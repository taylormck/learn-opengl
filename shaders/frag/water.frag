#version 330 core
out vec4 frag_color;

struct PointLight {
	vec3 position;
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
	vec3 emissive;
	float constant;
	float linear;
	float quadratic;
};

in vec3 frag_position;
in vec4 frag_clip_space_position;
in vec2 tex_coords;
in vec3 normal;

uniform vec3 color;
uniform float shininess;
uniform vec3 view_position;
uniform PointLight point_light;

uniform sampler3D noise;
uniform float noise_offset;

uniform sampler2D reflect_map;
uniform sampler2D refract_map;
uniform bool is_above;

const float fog_start = 1.0;
const float fog_end = 300.0;

vec3 calculate_point_light(PointLight light, vec3 color, vec3 norm) {
	vec3 ambient = light.ambient * color;

	vec3 light_diff = light.position - frag_position;
	vec3 light_dir = normalize(light_diff);
	float distance = length(light_diff);

	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * color;

	vec3 view_dir = normalize(view_position - frag_position);
	vec3 halfway_dir = normalize(light_dir + view_dir);
	float spec = pow(max(dot(norm, halfway_dir), 0.0), shininess);
	vec3 specular = light.specular * spec * 0.7;

	return ambient + diffuse + specular;
}

vec3 calculate_normal(float offset, float map_scale, float height_scale) {
	float y = fract(noise_offset);
	float h1 = texture(noise, vec3(tex_coords.s * map_scale, y, (tex_coords.t + offset) * map_scale)).r * height_scale;

	float h2 = texture(noise, vec3((tex_coords.s - offset) * map_scale, y, (tex_coords.t - offset) * map_scale)).r *
			   height_scale;

	float h3 = texture(noise, vec3((tex_coords.s + offset) * map_scale, y, (tex_coords.t - offset) * map_scale)).r *
			   height_scale;

	vec3 v1 = vec3(0.0, h1, -1.0);
	vec3 v2 = vec3(-1.0, h2, 1.0);
	vec3 v3 = vec3(1.0, h3, 1.0);
	vec3 v4 = v2 - v1;
	vec3 v5 = v3 - v1;

	return normalize(cross(v4, v5));
}

void main() {
	vec3 result;

	vec2 refract_coords = frag_clip_space_position.xy / (2.0 * frag_clip_space_position.w) + 0.5;
	vec3 refract_color = texture(refract_map, refract_coords).rgb;

	vec3 norm = calculate_normal(0.0002, 32.0, 16.0);
	refract_color = calculate_point_light(point_light, refract_color, norm);

	if (is_above) {
		vec2 reflect_coords =
			vec2(frag_clip_space_position.x, -frag_clip_space_position.y) / (2.0 * frag_clip_space_position.w) + 0.5;
		vec3 reflect_color = texture(reflect_map, reflect_coords).rgb;

		// vec3 norm = normalize(normal);
		vec3 view_dir = normalize(view_position - frag_position);
		float n_dot_l = max(dot(norm, view_dir), 0.0);
		float fresnel = acos(n_dot_l);

		// Fine-tuned numbers
		fresnel = pow(clamp(fresnel - 0.5, 0.0, 1.0), 3);

		result = mix(refract_color, reflect_color, fresnel);
	} else {
		result = 0.5 * color + 0.6 * refract_color;

		float dist = length(view_position - frag_position);
		float fog_factor = clamp(((fog_end - dist) / (fog_end - fog_start)), 0.0, 1.0);

		result = mix(color * 0.2, result, pow(fog_factor, 5));
	}

	frag_color = vec4(result, 1.0);
}
