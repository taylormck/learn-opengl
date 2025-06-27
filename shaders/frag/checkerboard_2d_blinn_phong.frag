#version 330 core
out vec4 frag_color;

struct DirectionalLight {
	vec3 direction;
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};

in vec3 frag_position;
in vec2 tex_coords;
in vec3 normal;

uniform vec3 color_01;
uniform vec3 color_02;
uniform vec3 color_03;
uniform float shininess;
uniform float tile_scale;

uniform sampler3D noise;
uniform float noise_offset;

uniform vec3 view_position;
uniform bool is_above;
uniform DirectionalLight directional_light;
uniform mat3 mit;

const float fog_start = 10.0;
const float fog_end = 300.0;
const float distortion_strengh = 2.0;

vec3 calculate_directional_light(DirectionalLight light, vec3 color, vec3 norm) {
	vec3 ambient = light.ambient * color;

	vec3 light_dir = normalize(-light.direction);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * color;

	vec3 view_dir = normalize(view_position - frag_position);
	vec3 halfway_dir = normalize(light_dir + view_dir);
	float spec = pow(max(dot(norm, halfway_dir), 0.0), shininess);
	vec3 specular = light.specular * spec * 0.7;

	return ambient + diffuse + specular;
}

vec3 calculate_wave_normal(vec2 tex_coords, float offset, float map_scale, float height_scale) {
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
	vec3 norm = normalize(normal);
	vec2 tc = tex_coords;

	if (is_above) {
		vec3 wave_normal = calculate_wave_normal(tex_coords / 25.0, 0.05, 32.0, 0.05);
		vec2 distortion = wave_normal.xz * distortion_strengh;
		tc += distortion;
	}

	float x = floor(tc.x * tile_scale);
	float y = floor(tc.y * tile_scale);

	float decider = mod(x + y, 2.0);

	vec3 color = mix(color_01, color_02, decider);
	color = calculate_directional_light(directional_light, color, norm);

	float dist = length(view_position - frag_position);
	float fog_factor = clamp(((fog_end - dist) / (fog_end - fog_start)), 0.0, 1.0);

	color = mix(color_03 * 0.1, color, pow(fog_factor, 5));

	frag_color = vec4(color, 1.0);
}
