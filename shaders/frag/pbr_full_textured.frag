#version 330 core
out vec4 frag_color;

in VS_OUT {
	vec3 world_position;
	vec3 normal;
	vec2 tex_coords;
}
fs_in;

uniform vec3 view_position;

uniform sampler2D albedo_map;
uniform sampler2D normal_map;
uniform sampler2D metallic_map;
uniform sampler2D roughness_map;
uniform sampler2D ao_map;

uniform samplerCube irradiance_map;
uniform samplerCube prefilter_map;
uniform sampler2D brdf_lut;

#define MAX_NUM_POINT_LIGHTS 4
uniform int num_point_lights;
uniform vec3 point_light_positions[MAX_NUM_POINT_LIGHTS];
uniform vec3 point_light_colors[MAX_NUM_POINT_LIGHTS];

const float PI = 3.14159265359;
const float MAX_REFLECTION_LOD = 4.0;

float distribution_ggx(vec3 h, vec3 n, float roughness) {
	float a = roughness * roughness;
	float a2 = a * a;
	float n_dot_h = max(dot(n, h), 0.0);
	float n_dot_h_2 = n_dot_h * n_dot_h;

	float numerator = a2;
	float denominator = n_dot_h_2 * (a2 - 1.0) + 1.0;
	denominator = PI * denominator * denominator;

	return numerator / denominator;
}

float geometry_schlick_ggx(float n_dot_v, float roughness) {
	float r = roughness + 1.0;
	float k = r * r / 8.0;

	float numerator = n_dot_v;
	float denominator = n_dot_v * (1.0 - k) + k;

	return numerator / denominator;
}

float geometry_smith(vec3 n, vec3 v, vec3 l, float roughness) {
	float n_dot_v = max(dot(n, v), 0.0);
	float n_dot_l = max(dot(n, l), 0.0);

	float ggx2 = geometry_schlick_ggx(n_dot_v, roughness);
	float ggx1 = geometry_schlick_ggx(n_dot_l, roughness);

	return ggx1 * ggx2;
}

vec3 fresnel_schlick(float cos_theta, vec3 f0) {
	return f0 + (1.0 - f0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
}

vec3 fresnel_schlick_roughness(float cos_theta, vec3 f0, float roughness) {
	return f0 + (max(vec3(1.0 - roughness), f0) - f0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
}

vec3 calculate_point_light_radiance(
	vec3 n,
	vec3 v,
	vec3 f0,
	vec3 albedo,
	float metallic,
	float roughness,
	int light_index
) {
	vec3 light_diff = point_light_positions[light_index] - fs_in.world_position;

	vec3 l = normalize(light_diff);
	vec3 h = normalize(v + l);

	float n_dot_l = max(dot(n, l), 0.0);
	float n_dot_v = max(dot(n, v), 0.0);

	float distance = length(light_diff);
	float attenuation = 1.0 / (distance * distance);

	// NOTE: I suspect that PI is supposed to be involved here.
	vec3 radiance = point_light_colors[light_index] * attenuation;

	float ndf = distribution_ggx(n, h, roughness);
	float g = geometry_smith(n, v, l, roughness);
	vec3 f = fresnel_schlick_roughness(clamp(dot(h, v), 0.0, 1.0), f0, roughness);

	vec3 numerator = ndf * g * f;
	float denominator = 4.0 * n_dot_v * n_dot_l + 0.00001;
	vec3 specular = numerator / denominator;

	vec3 kS = f;
	vec3 kD = vec3(1.0) - kS;
	kD *= 1.0 - metallic;

	return (kD * albedo / PI + specular) * radiance * n_dot_l;
}

vec3 calculate_tangent_space_normal() {
	vec3 tangent_normal = texture(normal_map, fs_in.tex_coords).xyz * 2.0 - 1.0;

	vec3 q1 = dFdx(fs_in.world_position);
	vec3 q2 = dFdy(fs_in.world_position);
	vec2 st1 = dFdx(fs_in.tex_coords);
	vec2 st2 = dFdy(fs_in.tex_coords);

	vec3 n = normalize(fs_in.normal);
	vec3 t = normalize(q1 * st2.t - q2 * st1.t);
	vec3 b = -normalize(cross(n, t));
	mat3 tbn = mat3(t, b, n);

	return normalize(tbn * tangent_normal);
}

void main() {
	vec3 albedo = texture(albedo_map, fs_in.tex_coords).rgb;
	float metallic = texture(metallic_map, fs_in.tex_coords).r;
	float roughness = texture(roughness_map, fs_in.tex_coords).r;
	float ao = texture(ao_map, fs_in.tex_coords).r;

	vec3 n = calculate_tangent_space_normal();
	vec3 v = normalize(view_position - fs_in.world_position);
	vec3 r = reflect(-v, n);

	// f0 is "reflectance at normal incidence".
	// Dielectric materials use a flat 0.04 value, metals use their albedo.
	vec3 f0 = mix(vec3(0.04), albedo, metallic);

	int num_point_lights = clamp(num_point_lights, 0, MAX_NUM_POINT_LIGHTS);
	vec3 Lo = vec3(0.0);
	for (int i = 0; i < num_point_lights; i += 1) {
		Lo += calculate_point_light_radiance(n, v, f0, albedo, metallic, roughness, i);
	}

	vec3 f = fresnel_schlick_roughness(max(dot(n, v), 0.0), f0, roughness);
	vec3 kS = f;
	vec3 kD = 1.0 - kS;
	kD *= 1.0 - metallic;

	vec3 irradiance = texture(irradiance_map, n).rgb;
	vec3 diffuse = irradiance * albedo;

	vec3 prefiltered_color = textureLod(prefilter_map, r, roughness * MAX_REFLECTION_LOD).rgb;
	vec2 brdf = texture(brdf_lut, vec2(max(dot(n, v), 0.0), roughness)).rg;
	vec3 specular = prefiltered_color * (f * brdf.x + brdf.y);

	vec3 ambient = (kD * diffuse + specular) * ao;

	vec3 color = ambient + Lo;

	// HDR
	color = color / (color + vec3(1.0));

	// Gamma correction
	color = pow(color, vec3(1.0 / 2.2));

	frag_color = vec4(color, 1.0f);
}
