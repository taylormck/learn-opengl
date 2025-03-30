#version 330 core

layout(location = 0) in vec3 vert_position;
out vec3 vert_color;

uniform float time;
uniform vec2 resolution;

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) { return a + b * cos(6.28318 * (c * t + d)); }

vec3 my_palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.0, 0.10, 0.20);

    return palette(t, a, b, c, d);
}

void main() {
    vert_color = vec3(my_palette(time + 1.752 * gl_VertexID));
    gl_Position = vec4(vert_position, 1.0);
}
