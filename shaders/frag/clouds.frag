#version 330 core
out vec4 frag_color;

in VS_OUT {
	vec3 frag_position;
	vec3 tex_coords;
}
fs_in;

uniform float zoom;
uniform float turbulence_power;
uniform sampler3D noise;
uniform bool use_logistic;
uniform float quant;

const float quant_multiplier = 256.0;

float get_smooth_value(vec3 co, vec3 texture_size) {
	vec3 texel_size = 1.0 / texture_size;

	vec3 tex_coords = co * texture_size;
	vec3 rounded_coords = floor(tex_coords);
	vec3 fractions = tex_coords - rounded_coords;
	vec3 inverse = vec3(1.0) - fractions;

	vec3 fract_coords = rounded_coords * texel_size;
	vec3 offset = fract_coords - texel_size;

	float value = 0.0;

	value += fractions.x * fractions.y * fractions.z * texture(noise, fract_coords).r;
	value += inverse.x * fractions.y * fractions.z * texture(noise, vec3(offset.x, fract_coords.yz)).r;
	value += fractions.x * inverse.y * fractions.z * texture(noise, vec3(fract_coords.x, offset.y, fract_coords.z)).r;
	value += inverse.x * inverse.y * fractions.z * texture(noise, vec3(offset.xy, fract_coords.z)).r;

	value += fractions.x * fractions.y * inverse.z * texture(noise, vec3(fract_coords.xy, offset.z)).r;
	value += inverse.x * fractions.y * inverse.z * texture(noise, vec3(offset.x, fract_coords.y, offset.z)).r;
	value += fractions.x * inverse.y * inverse.z * texture(noise, vec3(fract_coords.x, offset.yz)).r;
	value += inverse.x * inverse.y * inverse.z * texture(noise, offset).r;

	return value;
}

float logistic(float a) {
	return 1.0 / (1.0 + pow(2.718, -0.2 * a));
}

float turbulence(vec3 co, float max_zoom) {
	vec3 texture_size = textureSize(noise, 0);

	float current_zoom = max_zoom;
	float result = 0.0;

	while (current_zoom >= 1.0) {
		result += get_smooth_value(co, texture_size / current_zoom) * current_zoom;
		current_zoom /= 2.0;
	}

	result = 0.5 * result / max_zoom;

	if (use_logistic) {
		result = logistic((result - quant) * quant_multiplier);
	}

	return result;
}

void main() {
	float max_zoom = clamp(zoom, 1.0, 64.0);
	float turbulence = turbulence_power * turbulence(fs_in.tex_coords, max_zoom);

	float value = 1.0 - turbulence;

	float red = value;
	float green = value;
	float blue = 1.0;

	frag_color = vec4(red, green, blue, 1.0);
}
