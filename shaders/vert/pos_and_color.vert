#version 330 core

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec3 a_color;

out VS_OUT {
	vec3 vert_color;
}
vs_out;

void main() {
	gl_Position = vec4(a_position, 1.0);
	vs_out.vert_color = a_color;
}
