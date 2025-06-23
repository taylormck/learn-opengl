#version 330 core
out vec4 frag_color;

in VS_OUT {
	vec3 frag_position;
	vec3 tex_coords;
}
fs_in;

uniform float zoom;
uniform float turbulence_power;
uniform float vein_frequency;
uniform sampler3D noise;
uniform bool use_logistic;
uniform bvec3 enhance_colors;

vec3 get_smooth_value(vec3 co, vec3 texture_size) {
	vec3 texel_size = 1.0 / texture_size;

	vec3 tex_coords = co * texture_size;
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

	return value;
}

vec3 turbulence(vec3 co, float max_zoom) {
	vec3 texture_size = textureSize(noise, 0);

	float current_zoom = max_zoom;
	vec3 result = vec3(0.0);

	while (current_zoom >= 1.0) {
		result += get_smooth_value(co, texture_size / current_zoom) * current_zoom;
		current_zoom /= 2.0;
	}

	result = 0.5 * result / max_zoom;

	return result;
}

float logistic(float a) {
	return 1.0 / (1.0 + pow(2.718, -3 * a));
}

vec3 logistic(vec3 v) {
	return vec3(logistic(v.x), logistic(v.y), logistic(v.z));
}

float enhance_color(float a) {
	return min(a * 1.5 - 0.25, 1.0);
}

void main() {
	float max_zoom = clamp(zoom, 2.0, 64.0);
	vec3 turbulence = turbulence_power * turbulence(fs_in.tex_coords, max_zoom);

	vec3 value = fs_in.tex_coords.x + fs_in.tex_coords.y + fs_in.tex_coords.z + turbulence;
	value = abs(sin(value * 3.14159 * vein_frequency));

	if (use_logistic) {
		value = logistic(value);
		value = value * 1.25 - 0.2;
		value = clamp(value, -1.0, 1.0);
	}

	if (enhance_colors.x) {
		value.x = enhance_color(value.x);
	}

	if (enhance_colors.y) {
		value.y = enhance_color(value.y);
	}

	if (enhance_colors.z) {
		value.z = enhance_color(value.z);
	}

	frag_color = vec4(value, 1.0);
}
