package renderer

import "engine:math"

Color :: math.Vector4

Line :: struct {
    start, end : math.Vector3,
    thickness  : f32,
    color      : Color,
}

Quad :: struct {
    position   : math.Vector3,
    dimensions : math.Vector2,
    color      : Color,

    // @Todo: Textures
    // texture       : ^Texture_2D,
    // tiling_factor : f64 = 1.0,
}

Circle :: struct {
    position : math.Vector3,
    radius, thickness, fade : f32,
    color : Color,
}

// -----------------------------------------------------------------------------------

@(private="file")
Renderer_Storage :: struct {
    camera        : Camera,
    quad_mesh     : ^Mesh,
    quad_shader   : ^Shader,
    circle_shader : ^Shader,
    white_texture : ^Texture_2D,
}

@(private="file") g_renderer_storage : Renderer_Storage
@(private="file") white_texture_data := 0xff_ff_ff_ff

// -----------------------------------------------------------------------------------

init :: proc(width, height : int) {
    quad_indices  :: []u32 { 0, 1, 2, 0, 2, 3 };
    quad_vertices :: []Vertex {
        // @Robustness: The texture UVs assume top-down rendering, should probably have a choice about this.
        // { position = { -0.5, -0.5, 0.0 }, normal = { 0.0, 0.0, 0.0 }, uv_coords = { 0.0, 1.0 } },
        // { position = {  0.5, -0.5, 0.0 }, normal = { 0.0, 0.0, 0.0 }, uv_coords = { 1.0, 1.0 } },
        // { position = {  0.5,  0.5, 0.0 }, normal = { 0.0, 0.0, 0.0 }, uv_coords = { 1.0, 0.0 } },
        // { position = { -0.5,  0.5, 0.0 }, normal = { 0.0, 0.0, 0.0 }, uv_coords = { 0.0, 0.0 } },

        // @Note: Bottom-up rendering
        { position = { -0.5, -0.5, 0.0 }, normal = { 0.0, 0.0, 0.0 }, uv_coords = { 0.0, 0.0 } },
        { position = {  0.5, -0.5, 0.0 }, normal = { 0.0, 0.0, 0.0 }, uv_coords = { 1.0, 0.0 } },
        { position = {  0.5,  0.5, 0.0 }, normal = { 0.0, 0.0, 0.0 }, uv_coords = { 1.0, 1.0 } },
        { position = { -0.5,  0.5, 0.0 }, normal = { 0.0, 0.0, 0.0 }, uv_coords = { 0.0, 1.0 } },
    }

    using g_renderer_storage
    init_camera(&camera, 0, cast(f32) width, cast(f32) height, 0) // @Note: Bottom-up rendering
    // init_camera(&camera, 0, cast(f32) width, 0, cast(f32) height) // @Note: Top-down rendering
    quad_mesh     = new_mesh(quad_vertices, quad_indices)
    quad_shader   = new_2d_quad_shader()
    circle_shader = new_2d_circle_shader()
    white_texture = new_texture_2d(1, 1, rawptr(&white_texture_data))
}

destroy :: proc() {
    using g_renderer_storage
    free_mesh(quad_mesh)
    free_shader(quad_shader)
    free_shader(circle_shader)
    free_texture(white_texture)
}

draw_line :: proc(line : Line) {
    using g_renderer_storage
    using math

    enable_depth_test(true); defer enable_depth_test(false)
    enable_blending(true);   defer enable_blending(false)
    set_blend_function(.Source_Alpha, .One_Minus_Source_Alpha)
    set_cull_face(.None)

    line_dot    : f32 = vector_dot(line.end - line.start, math.Vector3{ 1, 0, 0 })
    line_length : f32 = vector_length(line.end - line.start)

    // @Note: (1, 0, 0) has length 1, so line_length * 1 is redundant
    angle : f32 = acos(line_dot / (line_length))

    transform := Transform{
        position = line.start + (line.end - line.start) / 2.0,
        rotation = create_rotation_radians({ 0, 0, angle }),
        scale    = { vector_length(line.end - line.start), line.thickness, 1 },
        parent   = Mat4x4_Identity,
    }

    bind_texture_to_slot(white_texture, 0); defer bind_texture_to_slot(nil, 0)
    bind_shader(quad_shader); defer bind_shader(nil)
    set_shader_uniform(quad_shader, "u_view_projection", matrix_flatten(get_view_projection_matrix(camera)))
    set_shader_uniform(quad_shader, "u_transform", matrix_flatten(get_world_transform(transform)))
    set_shader_uniform(quad_shader, "u_texture_slot", 0)
    set_shader_uniform(quad_shader, "u_color", line.color)
    set_shader_uniform(quad_shader, "u_tile_factor", 1.0)

    set_mesh_for_rendering(quad_mesh); defer set_mesh_for_rendering(nil)
    draw_indexed(quad_mesh)
}

draw_quad :: proc(quad : Quad) {
    using g_renderer_storage
    using math

    enable_depth_test(true); defer enable_depth_test(false)
    enable_blending(true);   defer enable_blending(false)
    set_blend_function(.Source_Alpha, .One_Minus_Source_Alpha)
    set_cull_face(.None)

    transform := Transform{
        position = quad.position,
        rotation = create_rotation_radians({ 0, 0, 0 }),
        scale    = { quad.dimensions.x, quad.dimensions.y, 1 },
        parent   = Mat4x4_Identity,
    }

    bind_texture_to_slot(white_texture, 0); defer bind_texture_to_slot(nil, 0)
    bind_shader(quad_shader); defer bind_shader(nil)
    set_shader_uniform(quad_shader, "u_view_projection", matrix_flatten(get_view_projection_matrix(camera)))
    set_shader_uniform(quad_shader, "u_transform", matrix_flatten(get_world_transform(transform)))
    set_shader_uniform(quad_shader, "u_texture_slot", 0)
    set_shader_uniform(quad_shader, "u_color", quad.color)
    set_shader_uniform(quad_shader, "u_tile_factor", 1.0)

    set_mesh_for_rendering(quad_mesh); defer set_mesh_for_rendering(nil)
    draw_indexed(quad_mesh)
}

draw_circle :: proc(circle : Circle) {
    using g_renderer_storage
    using math

    enable_depth_test(true); defer enable_depth_test(false)
    enable_blending(true);   defer enable_blending(false)
    set_blend_function(.Source_Alpha, .One_Minus_Source_Alpha)
    set_cull_face(.None)

    transform := Transform{
        position = circle.position,
        rotation = create_rotation_radians({ 0, 0, 0 }),
        scale    = { circle.radius, circle.radius, 1 },
        parent   = Mat4x4_Identity,
    }

    bind_shader(circle_shader); defer bind_shader(nil)
    set_shader_uniform(circle_shader, "u_view_projection", matrix_flatten(get_view_projection_matrix(camera)))
    set_shader_uniform(circle_shader, "u_transform", matrix_flatten(get_world_transform(transform)))
    set_shader_uniform(circle_shader, "u_color", circle.color)
    set_shader_uniform(circle_shader, "u_thickness", circle.thickness)
    set_shader_uniform(circle_shader, "u_fade", circle.fade if circle.fade > 1e-8 else 4.0 / circle.radius)

    set_mesh_for_rendering(quad_mesh); defer set_mesh_for_rendering(nil)
    draw_indexed(quad_mesh)
}

// -----------------------------------------------------------------------------------

@(private="file")
new_2d_quad_shader :: proc() -> (shader : ^Shader) {
    vertex_shader :: `
#version 450

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec2 in_uv;

layout(location = 0) out vec2 out_uv;

uniform mat4 u_view_projection;
uniform mat4 u_transform;

void main() {
    out_uv = in_uv;
    gl_Position = u_view_projection * u_transform * vec4(in_position, 1.0);
}
`

    fragment_shader :: `
#version 450

layout(location = 0) in vec2 in_uv;

layout(location = 0) out vec4 out_color;

uniform sampler2D u_texture_slot;
uniform vec4 u_color;
uniform float u_tile_factor;

void main() {
    vec4 color = texture(u_texture_slot, in_uv * u_tile_factor) * u_color;
    if(color.a <= 0.1) { discard; }
    out_color = color;
}
`

    return new_shader("2D_Quad", #partial [Shader_Stage]cstring{
        .Vertex = vertex_shader,
        .Fragment = fragment_shader,
    })
}

@(private="file")
new_2d_circle_shader :: proc() -> (shader : ^Shader) {
    vertex_shader :: `
#version 450

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec2 in_uv;

layout(location = 0) out vec2 out_uv;

uniform mat4 u_view_projection;
uniform mat4 u_transform;

void main() {
    out_uv = in_uv * 2.0 - 1.0;
    gl_Position = u_view_projection * u_transform * vec4(in_position, 1.0);
}
`

    fragment_shader :: `
#version 450

layout(location = 0) in vec2 in_uv;

layout(location = 0) out vec4 out_color;

uniform vec4 u_color;
uniform float u_thickness;
uniform float u_fade;

void main() {
    float dist = 1.0 - length(in_uv);
    float circle = smoothstep(0.0, u_fade, dist) * smoothstep(u_thickness + u_fade, u_thickness, dist);
    if(circle <= 0.0) { discard; }

    out_color = vec4(u_color.rgb, u_color.a * circle);
}
`

    return new_shader("2D_Circle", #partial [Shader_Stage]cstring{
        .Vertex = vertex_shader,
        .Fragment = fragment_shader,
    })
}
