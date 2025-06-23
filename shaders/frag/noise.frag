#version 330 core
out vec4 frag_color;

in VS_OUT {
	vec3 frag_position;
	vec3 tex_coords;
}
fs_in;

uniform float zoom;
uniform sampler3D noise;

void main() {
	vec3 sample_coords = fs_in.tex_coords / zoom;
	vec3 value = texture(noise, sample_coords).rgb;

	frag_color = vec4(value, 1.0);
}
