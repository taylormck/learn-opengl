#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 2) in vec3 aNormal;

out VS_OUT {
	vec3 normal;
}
vs_out;

uniform mat4 view_model;
uniform mat3 mit;

void main() {
	gl_Position = view_model * vec4(aPos, 1.0);
	vs_out.normal = normalize(mit * aNormal);
}
