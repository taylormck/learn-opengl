#version 330 core
out vec4 frag_color;

in VS_OUT {
	vec3 world_position;
	vec3 normal;
	vec2 tex_coords;
}
fs_in;

uniform vec3 view_position;

uniform vec3 albedo;
uniform float metallic;
uniform float roughness;
uniform float ao;

uniform samplerCube irradiance_map;

#define MAX_NUM_POINT_LIGHTS 4
uniform int num_point_lights;
uniform vec3 point_light_positions[MAX_NUM_POINT_LIGHTS];
uniform vec3 point_light_colors[MAX_NUM_POINT_LIGHTS];

const float PI = 3.14159265359;

float distribution_ggx(vec3 h, vec3 n) {
	float a = roughness * roughness;
	float a2 = a * a;
	float n_dot_h = max(dot(n, h), 0.0);
	float n_dot_h_2 = n_dot_h * n_dot_h;

	float numerator = a2;
	float denominator = n_dot_h_2 * (a2 - 1.0) + 1.0;
	denominator = PI * denominator * denominator;

	return numerator / denominator;
}

float geometry_schlick_ggx(float n_dot_v) {
	float r = roughness + 1.0;
	float k = r * r / 8.0;

	float numerator = n_dot_v;
	float denominator = n_dot_v * (1.0 - k) + k;

	return numerator / denominator;
}

float geometry_smith(vec3 n, vec3 v, vec3 l) {
	float n_dot_v = max(dot(n, v), 0.0);
	float n_dot_l = max(dot(n, l), 0.0);

	float ggx2 = geometry_schlick_ggx(n_dot_v);
	float ggx1 = geometry_schlick_ggx(n_dot_l);

	return ggx1 * ggx2;
}

vec3 fresnel_schlick(float cos_theta, vec3 f0) {
	return f0 + (1.0 - f0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
}

vec3 fresnel_schlick_roughness(float cos_theta, vec3 f0, float roughness) {
	return f0 + (max(vec3(1.0 - roughness), f0) - f0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
}

vec3 calculate_point_light_radiance(vec3 n, vec3 v, vec3 f0, int light_index) {
	vec3 light_diff = point_light_positions[light_index] - fs_in.world_position;

	vec3 l = normalize(light_diff);
	vec3 h = normalize(v + l);

	float n_dot_l = max(dot(n, l), 0.0);
	float n_dot_v = max(dot(n, v), 0.0);

	float distance = length(light_diff);
	float attenuation = 1.0 / (distance * distance);

	// NOTE: I suspect that PI is supposed to be involved here.
	vec3 radiance = point_light_colors[light_index] * attenuation;

	float ndf = distribution_ggx(n, h);
	float g = geometry_smith(n, v, l);
	vec3 f = fresnel_schlick(clamp(dot(h, v), 0.0, 1.0), f0);

	vec3 numerator = ndf * g * f;
	float denominator = 4.0 * n_dot_v * n_dot_l + 0.00001;
	vec3 specular = numerator / denominator;

	vec3 kS = f;
	vec3 kD = vec3(1.0) - kS;
	kD *= 1.0 - metallic;

	return (kD * albedo / PI + specular) * radiance * n_dot_l;
}

void main() {
	vec3 n = normalize(fs_in.normal);
	vec3 v = normalize(view_position - fs_in.world_position);

	// f0 is "reflectance at normal incidence".
	// Dielectric materials use a flat 0.04 value, metals use their albedo.
	vec3 f0 = mix(vec3(0.04), albedo, metallic);

	int num_point_lights = clamp(num_point_lights, 0, MAX_NUM_POINT_LIGHTS);
	vec3 Lo = vec3(0.0);
	for (int i = 0; i < num_point_lights; i += 1) {
		Lo += calculate_point_light_radiance(n, v, f0, i);
	}

	vec3 kS = fresnel_schlick_roughness(max(dot(n, v), 0.0), f0, roughness);
	vec3 kD = 1.0 - kS;

	vec3 irradiance = texture(irradiance_map, n).rgb;
	vec3 diffuse = irradiance * albedo;
	vec3 ambient = kD * diffuse * ao;

	vec3 color = ambient + Lo;

	// HDR
	color = color / (color + vec3(1.0));

	// Gamma correction
	color = pow(color, vec3(1.0 / 2.2));

	frag_color = vec4(color, 1.0f);
}
