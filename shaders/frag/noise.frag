#version 330 core
out vec4 frag_color;

in VS_OUT {
	vec3 frag_position;
	vec2 tex_coords;
}
fs_in;

uniform float zoom;
uniform sampler3D noise;

/*
noise_index := get_noise_index(x / zoom, y / zoom, z / zoom)
noise_value := u8(noise[noise_index] * 255)

data_start_index := get_noise_index(x, y, z) * 4
for data_index in data_start_index ..< data_start_index + 3 {
	data[data_index] = noise_value
}
data[data_start_index + 3] = 255
*/

void main() {
	vec3 sample_coords = vec3(fs_in.tex_coords, fs_in.frag_position.z) / zoom;
	vec3 value = texture(noise, sample_coords).rgb;

	frag_color = vec4(value, 1.0);
}
