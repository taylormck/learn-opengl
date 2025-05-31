#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;
layout(location = 2) in vec3 aNormal;

out VS_OUT {
	vec3 frag_position;
	vec3 normal;
	vec2 tex_coords;
}
vs_out;

uniform mat4 transform;
uniform mat4 model;
uniform mat3 mit;

void main() {
	gl_Position = transform * vec4(aPos, 1.0);
	vs_out.frag_position = vec3(model * vec4(aPos, 1.0));
	vs_out.tex_coords = aTexCoord;
	vs_out.normal = mit * aNormal;
}
