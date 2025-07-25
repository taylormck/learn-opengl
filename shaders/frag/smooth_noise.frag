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
	vec3 texture_size = textureSize(noise, 0) / zoom;
	vec3 texel_size = 1.0 / texture_size;

	vec3 tex_coords = fs_in.tex_coords * texture_size;
	vec3 rounded_coords = floor(tex_coords);
	vec3 fractions = tex_coords - rounded_coords;
	vec3 inverse = vec3(1.0) - fractions;

	vec3 fract_coords = rounded_coords * texel_size;
	vec3 offset = fract_coords - texel_size;

	vec3 value = vec3(0.0);

	value += fractions.x * fractions.y * fractions.z * texture(noise, fract_coords).rgb;
	value += inverse.x * fractions.y * fractions.z * texture(noise, vec3(offset.x, fract_coords.yz)).rgb;
	value += fractions.x * inverse.y * fractions.z * texture(noise, vec3(fract_coords.x, offset.y, fract_coords.z)).rgb;
	value += inverse.x * inverse.y * fractions.z * texture(noise, vec3(offset.xy, fract_coords.z)).rgb;

	value += fractions.x * fractions.y * inverse.z * texture(noise, vec3(fract_coords.xy, offset.z)).rgb;
	value += inverse.x * fractions.y * inverse.z * texture(noise, vec3(offset.x, fract_coords.y, offset.z)).rgb;
	value += fractions.x * inverse.y * inverse.z * texture(noise, vec3(fract_coords.x, offset.yz)).rgb;
	value += inverse.x * inverse.y * inverse.z * texture(noise, offset).rgb;

	frag_color = vec4(value, 1.0);
}
