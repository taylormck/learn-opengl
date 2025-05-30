#version 330 core

out vec4 frag_color;
in vec2 tex_coords;

uniform sampler2D depth_map;
uniform float near;
uniform float far;
uniform bool linearize;

float linearize_depth(float depth) {
	float z = depth * 2.0 - 1.0;

	return (2 * near * far) / (far + near - z * (far - near));
}

void main() {
	float depth = texture(depth_map, tex_coords).r;

	if (linearize) {
		frag_color = vec4(vec3(linearize_depth(depth) / far), 1.0);
	} else {
		frag_color = vec4(vec3(depth), 1.0);
	}
}
