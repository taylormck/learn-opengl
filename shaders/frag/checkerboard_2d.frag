#version 330 core
out vec4 frag_color;

in vec2 tex_coords;

uniform vec3 color_01;
uniform vec3 color_02;
uniform float tile_scale;

void main() {
	float x = floor(tex_coords.x * tile_scale);
	float y = floor(tex_coords.y * tile_scale);

	float decider = mod(x + y, 2.0);

	vec3 color = mix(color_01, color_02, decider);
	frag_color = vec4(color, 1.0);
}
