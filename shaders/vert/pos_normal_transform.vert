#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 2) in vec3 aNormal;

out vec3 frag_position;
out vec3 normal;

uniform mat4 transform;
uniform mat4 model;
uniform mat3 mit;

uniform bool invert_normals;

void main() {
	gl_Position = transform * vec4(aPos, 1.0);
	frag_position = vec3(model * vec4(aPos, 1.0));
	normal = mit * aNormal;

	if (invert_normals) {
		normal = -normal;
	}
}
