#version 330 core
layout(location = 0) in vec3 aPos;

out vec3 position;

uniform mat4 model;
uniform mat4 transform;

void main() {
	position = aPos;
	gl_Position = transform * vec4(aPos, 1.0);
}
