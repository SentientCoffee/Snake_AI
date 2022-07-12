#type VERTEX

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

#type FRAGMENT

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
