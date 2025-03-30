#version 330 core

layout(location = 0) in vec3 vert_position;
layout(location = 1) in vec3 vert_color;

out vec3 my_color;

void main() {
    gl_Position = vec4(vert_position, 1.0);
    my_color = vert_color;
}
