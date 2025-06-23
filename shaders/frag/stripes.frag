#version 330 core
out vec4 frag_color;

in VS_OUT {
	vec3 frag_position;
	vec2 tex_coords;
}
fs_in;

uniform vec3 color_01;
uniform vec3 color_02;
uniform float frequency;

void main() {
	float stripe = fs_in.tex_coords.y * frequency;
	int stripe_i = int(stripe);
	vec3 color = mix(color_01, color_02, float(stripe_i % 2));
	frag_color = vec4(color, 1.0);
}
