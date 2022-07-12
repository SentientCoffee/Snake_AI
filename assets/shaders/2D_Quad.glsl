#type VERTEX

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

#type FRAGMENT

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
