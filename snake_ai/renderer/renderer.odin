package renderer

Quad :: struct {
    position : Vector3,
    dimensions : Vector2,
    tint : Color,

    // @Todo: Textures
    // texture : rawptr = nil
    // tiling_factor : f64 = 1.0,
}

// -----------------------------------------------------------------------------------

@(private="file")
Renderer_Storage :: struct {
    camera        : Camera,
    quad_mesh     : ^Mesh,
    quad_shader   : ^Shader,
    white_texture : ^Texture2D,
}

@(private="file") g_renderer_storage : Renderer_Storage
@(private="file") white_texture_data := 0xff_ff_ff_ff

// -----------------------------------------------------------------------------------


init_renderer :: proc(width, height : int) {
    quad_indices  :: []u32 { 0, 1, 2, 0, 2, 3 };
    quad_vertices :: []Vertex {
        Vertex{ position = Vector3{ -0.5, -0.5, 0.0 }, normal = Vector3{ 0.0, 0.0, 0.0 }, uv_coords = Vector2{ 0.0, 1.0 } },
        Vertex{ position = Vector3{  0.5, -0.5, 0.0 }, normal = Vector3{ 0.0, 0.0, 0.0 }, uv_coords = Vector2{ 1.0, 1.0 } },
        Vertex{ position = Vector3{  0.5,  0.5, 0.0 }, normal = Vector3{ 0.0, 0.0, 0.0 }, uv_coords = Vector2{ 1.0, 0.0 } },
        Vertex{ position = Vector3{ -0.5,  0.5, 0.0 }, normal = Vector3{ 0.0, 0.0, 0.0 }, uv_coords = Vector2{ 0.0, 0.0 } },
    }

    using g_renderer_storage
    init_camera(&camera, 0, cast(f32) width, 0, cast(f32) height)
    quad_mesh = new_mesh(quad_vertices, quad_indices)
    quad_shader = new_2d_quad_shader()
    white_texture = new_texture_2d(1, 1, rawptr(&white_texture_data))

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
}

deinit_renderer :: proc() {
    using g_renderer_storage
    free_mesh(quad_mesh)
    free_shader(quad_shader)
}

draw_quad :: proc(quad : Quad) {
    using g_renderer_storage
    defer {
        enable_depth_test(false)
        // disable_blending()
        // set_blend_function(.Source_Alpha, .One_Minus_Source_Alpha)
        set_mesh_for_rendering(nil)
        bind_shader(nil)
        for i in  0..= 24 { bind_texture_to_slot(nil, cast(u32) i) }
    }

    enable_depth_test(true)
    set_cull_face(.None)
    // enable_blending()
    // set_blend_function_separate(.Source_Alpha, .One_Minus_Source_Alpha, .One, .One_Minus_Source_Alpha)

    transform := Transform{
        position = quad.position,
        rotation = create_rotation_radians(Vector3{ 0, 0, 0 }),
        scale    = Vector3{ quad.dimensions.x, quad.dimensions.y, 1 },
        parent   = Mat4x4_Identity,
    }

    bind_texture_to_slot(white_texture, 0)
    bind_shader(quad_shader)
    set_shader_uniform(quad_shader, "u_view_projection", matrix_flatten(get_view_projection_matrix(camera)))
    set_shader_uniform(quad_shader, "u_transform", matrix_flatten(get_world_transform(transform)))
    set_shader_uniform(quad_shader, "u_texture_slot", 0)
    set_shader_uniform(quad_shader, "u_color", quad.tint)
    set_shader_uniform(quad_shader, "u_tile_factor", 1.0)

    set_mesh_for_rendering(quad_mesh)
    draw_indexed(quad_mesh)
}
