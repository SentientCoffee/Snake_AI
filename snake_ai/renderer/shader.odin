package renderer

import log "../logging"

import "core:intrinsics"
import "core:fmt"
import "core:mem"
import "core:strings"

import gl "vendor:OpenGL"

Shader_Data_Type :: enum {
    Float, Float2, Float3, Float4,
    Int, Int2, Int3, Int4, Bool,
    Mat3, Mat4,
};


Shader_Stage :: enum {
    Vertex = 0,
    Tess_Control,
    Tess_Evaluation,
    Geometry,
    Fragment,
    Compute,
}

Uniform_Data_Type :: enum u32 {
    Float       = gl.FLOAT,
    Float2      = gl.FLOAT_VEC2,
    Float3      = gl.FLOAT_VEC3,
    Float4      = gl.FLOAT_VEC4,
    Int         = gl.INT,
    Int2        = gl.INT_VEC2,
    Int3        = gl.INT_VEC3,
    Int4        = gl.INT_VEC4,
    Mat3        = gl.FLOAT_MAT3,
    Mat4        = gl.FLOAT_MAT4,
    Sampler1D   = gl.SAMPLER_1D,
    Sampler2D   = gl.SAMPLER_2D,
    Sampler3D   = gl.SAMPLER_3D,
    SamplerCube = gl.SAMPLER_CUBE,
};

Uniform :: struct {
    type     : typeid,
    location : i32,
    count    : u32,
}

Shader :: struct {
    program_id : u32,
    handles    : [Shader_Stage]u32,
    uniforms   : map[string]Uniform,
    name       : string,
}

new_shader :: proc(name : string, stages : [Shader_Stage]cstring) -> (shader : ^Shader) {
    get_shader_error :: proc(handle : u32) -> (ok : bool, error_log : cstring) {
        ok = false
        error_log = ""

        success : i32 = 0
        if gl.GetShaderiv(handle, gl.COMPILE_STATUS, &success); success > 0 {
            ok = true
            return
        }

        log_length : i32
        gl.GetShaderiv(handle, gl.INFO_LOG_LENGTH, &log_length)
        info_log := make([]u8, log_length)
        gl.GetShaderInfoLog(handle, log_length, nil, raw_data(info_log))

        error_log = strings.clone_to_cstring(strings.clone_from(info_log))
        return
    }

    stages := stages
    shader_ident := fmt.tprintf("Shader - {}", name)
    shader = new(Shader)
    shader.name = name

    for src, i in &stages {
        if len(src) == 0 { continue }

        stage := Shader_Stage(i)
        log.debug(shader_ident, "Attaching {} shader...", stage)
        shader_handle : u32 = 0

        switch stage {
            case .Vertex:          shader_handle = gl.CreateShader(gl.VERTEX_SHADER)
            case .Tess_Control:    shader_handle = gl.CreateShader(gl.TESS_CONTROL_SHADER)
            case .Tess_Evaluation: shader_handle = gl.CreateShader(gl.TESS_EVALUATION_SHADER)
            case .Geometry:        shader_handle = gl.CreateShader(gl.GEOMETRY_SHADER)
            case .Fragment:        shader_handle = gl.CreateShader(gl.FRAGMENT_SHADER)
            case .Compute:         shader_handle = gl.CreateShader(gl.COMPUTE_SHADER)
        }

        shader.handles[stage] = shader_handle
        gl.ShaderSource(shader_handle, 1, &src, nil)
        gl.CompileShader(shader_handle)

        when ODIN_DEBUG {
            if ok, error_log := get_shader_error(shader_handle); !ok {
                log.error(shader_ident, "Failed to compile {} shader!\n{}", stage, error_log)
                gl.DeleteShader(shader_handle)
            }
        }
    }

    get_program_error :: proc(handle : u32) -> (ok : bool, error_log : cstring) {
        ok = false
        error_log = ""

        success : i32 = 0
        if gl.GetProgramiv(handle, gl.LINK_STATUS, &success); success > 0 {
            ok = true
            return
        }

        log_length : i32
        gl.GetProgramiv(handle, gl.INFO_LOG_LENGTH, &log_length)
        info_log := make([]u8, log_length)
        gl.GetProgramInfoLog(handle, log_length, nil, raw_data(info_log))

        error_log = strings.clone_to_cstring(strings.clone_from(info_log))
        return
    }

    program_id : u32 = gl.CreateProgram()
    for handle in shader.handles {
        if handle == 0 { continue }
        gl.AttachShader(program_id, handle)
    }
    gl.LinkProgram(program_id)

    when ODIN_DEBUG {
        if ok, error_log := get_program_error(program_id); !ok {
            log.error(shader_ident, "Failed to link shader program!\n{}", error_log)

            gl.DeleteProgram(program_id)
            for handle in shader.handles {
                if handle == 0 { continue }
                gl.DeleteShader(handle)
            }

            program_id = 0
        }
    }

    for handle in shader.handles {
        if handle == 0 { continue }
        gl.DetachShader(program_id, handle)
    }

    shader.program_id = program_id

    uniform_count : i32
    gl.GetProgramiv(program_id, gl.ACTIVE_UNIFORMS, &uniform_count)
    if (uniform_count == 0) { return }
    shader.uniforms = make(map[string]Uniform, uniform_count)

    max_name_length : i32
    gl.GetProgramiv(program_id, gl.ACTIVE_UNIFORM_MAX_LENGTH, &max_name_length);

    buffer := make([]u8, max_name_length)
    for i in 0 ..< u32(uniform_count) {
        length, count : i32
        type : u32 = gl.NONE
        mem.set(raw_data(buffer), 0, cast(int) max_name_length)

        gl.GetActiveUniform(program_id, i, max_name_length, &length, &count, &type, raw_data(buffer));
        uniform_name := strings.clone_from(raw_data(buffer), cast(int) length)

        uniform_info : Uniform
        uniform_info.location = gl.GetUniformLocation(program_id, strings.clone_to_cstring(uniform_name))
        uniform_info.count = u32(count)

        switch type {
            case gl.INT:          uniform_info.type = typeid_of(   i32)
            case gl.INT_VEC2:     uniform_info.type = typeid_of([^]i32)
            case gl.INT_VEC3:     uniform_info.type = typeid_of([^]i32)
            case gl.INT_VEC4:     uniform_info.type = typeid_of([^]i32)
            case gl.FLOAT:        uniform_info.type = typeid_of(   f32)
            case gl.FLOAT_VEC2:   uniform_info.type = typeid_of([^]f32)
            case gl.FLOAT_VEC3:   uniform_info.type = typeid_of([^]f32)
            case gl.FLOAT_VEC4:   uniform_info.type = typeid_of([^]f32)
            case gl.FLOAT_MAT3:   uniform_info.type = typeid_of([^]f32)
            case gl.FLOAT_MAT4:   uniform_info.type = typeid_of([^]f32)
            case gl.SAMPLER_1D:   uniform_info.type = typeid_of(   i32)
            case gl.SAMPLER_2D:   uniform_info.type = typeid_of(   i32)
            case gl.SAMPLER_3D:   uniform_info.type = typeid_of(   i32)
            case gl.SAMPLER_CUBE: uniform_info.type = typeid_of(   i32)
            case:                 uniform_info.type = nil
        }

        shader.uniforms[uniform_name] = uniform_info
    }
    when ODIN_DEBUG {
        log.debug(shader_ident, "Found uniforms:")
        for n, u in shader.uniforms {
            t := fmt.tprintf("{}", u.type)
            log.debug(shader_ident, "    {:-*s}: {:*s} - location {}, count {}", max_name_length, n, 6, t, u.location, u.count)
        }
    }
    return
}

free_shader :: proc(using shader : ^Shader) {
    gl.DeleteProgram(program_id)
    delete(uniforms)
    free(shader)
}

bind_shader :: proc(using shader : ^Shader) {
    if shader != nil {
        when ODIN_DEBUG {
            shader_ident := fmt.tprintf("Shader - {}", name)
            log.assert(program_id != 0, shader_ident, "Invalid shader program, unable to bind")
        }
        gl.UseProgram(program_id)
    }
    else {
        gl.UseProgram(0)
    }
}

set_shader_uniform :: proc(using shader : ^Shader, uniform_name : string, value : $Value_Type) {
    value := value

    u : Uniform
    ok : bool
    when ODIN_DEBUG {
        shader_ident := fmt.tprintf("Shader - {}", name)
        if u, ok = uniforms[uniform_name]; !ok {
            log.error(shader_ident, "Could not find uniform {}!", uniform_name)
            return
        }
    }
    else {
        if u, ok = shader.uniforms[uniform_name]; !ok { return }
    }

    when ODIN_DEBUG {
        log.assert(
            type_of(typeid_of(Value_Type)) == type_of(u.type),
            shader_ident, "Incorrect type for uniform {} (wanted {}, got {})",
            uniform_name, u.type, typeid_of(Value_Type),
        )
    }

    set_shader_uniform_type(u.location, value)
}

set_shader_uniform_type :: proc {
    set_shader_uniform_bool,
    set_shader_uniform_int,
    set_shader_uniform_int2,
    set_shader_uniform_int3,
    set_shader_uniform_int4,
    set_shader_uniform_float,
    set_shader_uniform_float2,
    set_shader_uniform_float3,
    set_shader_uniform_float4,
    set_shader_uniform_mat3x3,
    set_shader_uniform_mat4x4,
}

is_int   :: intrinsics.type_is_integer
is_float :: intrinsics.type_is_float

set_shader_uniform_bool   :: #force_inline proc(location : i32, value  :              bool)                      { gl.Uniform1i       (location,                i32( value )) }
set_shader_uniform_int    :: #force_inline proc(location : i32, value  :             $Type) where is_int  (Type) { gl.Uniform1i       (location,                i32( value )) }
set_shader_uniform_float  :: #force_inline proc(location : i32, value  :             $Type) where is_float(Type) { gl.Uniform1f       (location,                f32( value )) }
set_shader_uniform_int2   :: #force_inline proc(location : i32, values :   $IntVec/[ 2]i32)    { values := values; gl.Uniform2iv      (location, 1,        raw_data( values)) }
set_shader_uniform_int3   :: #force_inline proc(location : i32, values :   $IntVec/[ 3]i32)    { values := values; gl.Uniform3iv      (location, 1,        raw_data( values)) }
set_shader_uniform_int4   :: #force_inline proc(location : i32, values :   $IntVec/[ 4]i32)    { values := values; gl.Uniform4iv      (location, 1,        raw_data( values)) }
set_shader_uniform_float2 :: #force_inline proc(location : i32, values : $FloatVec/[ 2]f32)    { values := values; gl.Uniform2fv      (location, 1,        raw_data( values)) }
set_shader_uniform_float3 :: #force_inline proc(location : i32, values : $FloatVec/[ 3]f32)    { values := values; gl.Uniform3fv      (location, 1,        raw_data( values)) }
set_shader_uniform_float4 :: #force_inline proc(location : i32, values : $FloatVec/[ 4]f32)    { values := values; gl.Uniform4fv      (location, 1,        raw_data(&values)) }
set_shader_uniform_mat3x3 :: #force_inline proc(location : i32, values :           [ 9]f32)    { values := values; gl.UniformMatrix3fv(location, 1, false, raw_data(&values)) }
set_shader_uniform_mat4x4 :: #force_inline proc(location : i32, values :           [16]f32)    { values := values; gl.UniformMatrix4fv(location, 1, false, raw_data(&values)) }

// gl.Uniform1iv(location, count, reinterpret_cast<const GLint*>(values))
// gl.Uniform1iv(location, count, values)
// gl.Uniform1fv(location, count, values)
// gl.Uniform2fv(location, count, glm::value_ptr(values[0]))
// gl.Uniform3fv(location, count, glm::value_ptr(values[0]))
// gl.Uniform4fv(location, count, glm::value_ptr(values[0]))
// gl.UniformMatrix3fv(location, count, GL_FALSE, glm::value_ptr(values[0]))
// gl.UniformMatrix4fv(location, count, GL_FALSE, glm::value_ptr(values[0]))
