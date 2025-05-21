#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;
layout(location = 2) in vec3 aNormal;
layout(location = 3) in mat4 model;

out vec3 frag_position;
out vec3 normal;
out vec2 tex_coords;

uniform mat4 pv;

void main() {
	mat4 transform = pv * model;
	mat3 mit = mat3(transpose(inverse(model)));

	gl_Position = transform * vec4(aPos, 1.0);
	frag_position = vec3(model * vec4(aPos, 1.0));
	tex_coords = aTexCoord;
	normal = mit * aNormal;
}
