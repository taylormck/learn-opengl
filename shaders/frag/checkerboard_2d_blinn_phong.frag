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
in vec2 tex_coords;
in vec3 normal;

uniform vec3 color_01;
uniform vec3 color_02;
uniform float shininess;
uniform float tile_scale;

uniform vec3 view_position;
uniform PointLight point_light;

vec3 calculate_point_light(PointLight light, vec3 color) {
	vec3 ambient = light.ambient * color * 0.4;

	vec3 norm = normalize(normal);
	vec3 light_diff = light.position - frag_position;
	vec3 light_dir = normalize(light_diff);
	float distance = length(light_diff);

	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * color;

	vec3 specular = vec3(0.0);

	if (dot(norm, light_dir) > 0.0) {
		vec3 view_dir = normalize(view_position - frag_position);

		vec3 halfway_dir = normalize(light_dir + view_dir);
		float spec = pow(max(dot(norm, halfway_dir), 0.0), shininess);

		specular = light.specular * spec * 0.7;
	}

	float attenuation = 1.0 / distance * distance;

	return ambient + (diffuse + specular) * attenuation;
}

void main() {
	float x = floor(tex_coords.x * tile_scale);
	float y = floor(tex_coords.y * tile_scale);

	float decider = mod(x + y, 2.0);

	vec3 color = mix(color_01, color_02, decider);
	color = calculate_point_light(point_light, color);

	frag_color = vec4(color, 1.0);
}
