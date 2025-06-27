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

uniform vec3 view_position;
uniform bool is_above;
uniform DirectionalLight directional_light;

const float fog_start = 10.0;
const float fog_end = 300.0;

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

void main() {
	vec3 norm = normalize(normal);
	float x = floor(tex_coords.x * tile_scale);
	float y = floor(tex_coords.y * tile_scale);

	float decider = mod(x + y, 2.0);

	vec3 color = mix(color_01, color_02, decider);
	color = calculate_directional_light(directional_light, color, norm);

	float dist = length(view_position - frag_position);
	float fog_factor = clamp(((fog_end - dist) / (fog_end - fog_start)), 0.0, 1.0);

	color = mix(color_03 * 0.1, color, pow(fog_factor, 5));

	frag_color = vec4(color, 1.0);
}
