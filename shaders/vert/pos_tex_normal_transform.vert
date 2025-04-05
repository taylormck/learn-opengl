#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;
layout(location = 2) in vec3 aNormal;

out vec3 frag_position;
out vec3 normal;
out vec2 tex_coords;

uniform mat4 transform;
uniform mat4 model;
uniform mat3 mit;

void main() {
    gl_Position = transform * vec4(aPos, 1.0);
    frag_position = vec3(model * vec4(aPos, 1.0));
    tex_coords = aTexCoord;
    normal = mit * aNormal;
}
