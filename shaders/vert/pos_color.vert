#version 330 core

layout(location = 0) in vec3 aPosition;
layout(location = 3) in vec3 aColor;

out vec3 vert_color;

void main() {
	gl_Position = vec4(aPosition, 1.0);
	vert_color = aColor;
}
