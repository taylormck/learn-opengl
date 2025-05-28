#version 330 core
layout(location = 0) in vec3 aPos;

layout(std140) uniform Matrices {
	mat4 projection_view;
};

uniform mat4 model;

void main() {
	gl_Position = projection_view * model * vec4(aPos, 1.0);
}
