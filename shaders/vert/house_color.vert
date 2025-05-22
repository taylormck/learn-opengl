#version 330 core

layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aColor;

out VS_OUT {
	vec3 vert_color;
}
vs_out;

void main() {
	gl_Position = vec4(aPosition, 1.0);
	vs_out.vert_color = aColor;
}
