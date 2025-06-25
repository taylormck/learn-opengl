#version 330 core
out vec4 frag_color;

in VS_OUT {
	vec3 frag_position;
	vec3 tex_coords;
}
fs_in;

uniform vec3 color_01;
uniform vec3 color_02;
uniform float frequency;

void main() {
	int x = int(fs_in.tex_coords.x * frequency) % 2;
	int y = int(fs_in.tex_coords.y * frequency) % 2;
	int z = int(fs_in.tex_coords.z * frequency) % 2;

	int divider = x + y + z;

	vec3 color = mix(color_01, color_02, float(divider % 2));
	frag_color = vec4(color, 1.0);
}
