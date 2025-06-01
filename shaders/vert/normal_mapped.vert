#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;
layout(location = 2) in vec3 aNormal;
layout(location = 4) in vec3 aTangent;
layout(location = 5) in vec3 aBitangent;

out VS_OUT {
	vec3 frag_position;
	vec2 tex_coords;
	vec3 tangent_light_position;
	vec3 tangent_view_position;
	vec3 tangent_frag_position;
}
vs_out;

uniform mat4 transform;
uniform mat4 model;
uniform mat3 mit;

uniform vec3 light_position;
uniform vec3 view_position;

void main() {
	gl_Position = transform * vec4(aPos, 1.0);
	vs_out.frag_position = vec3(model * vec4(aPos, 1.0));
	vs_out.tex_coords = aTexCoord;

	vec3 T = normalize(mit * aTangent);
	vec3 N = normalize(mit * aNormal);
	T = normalize(T - dot(T, N) * N);
	vec3 B = cross(N, T);

	mat3 TBN = transpose(mat3(T, B, N));
	vs_out.tangent_light_position = TBN * light_position;
	vs_out.tangent_view_position = TBN * view_position;
	vs_out.tangent_frag_position = TBN * vs_out.frag_position;
}
