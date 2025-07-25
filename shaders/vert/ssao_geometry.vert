#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 2) in vec3 aNormal;

out vec3 frag_position;
out vec3 normal;

uniform bool invert_normals;

uniform mat4 model_view;
uniform mat3 model_view_it;
uniform mat4 projection;

void main() {
	vec4 view_position = model_view * vec4(aPos, 1.0);
	frag_position = view_position.xyz;

	normal = invert_normals ? -aNormal : aNormal;
	normal = model_view_it * normal;

	gl_Position = projection * view_position;
}
