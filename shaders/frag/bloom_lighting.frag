#version 330 core
layout(location = 0) out vec4 frag_color;
layout(location = 1) out vec4 bright_color;

struct Material {
	sampler2D diffuse_0;
	vec3 specular;
	float shininess;
};

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

uniform bool full_attenuation;
uniform vec3 view_position;
uniform Material material;

#define MAX_NUM_POINT_LIGHTS 4
uniform int num_point_lights;

uniform PointLight point_lights[MAX_NUM_POINT_LIGHTS];

const vec3 brightness_threshold = vec3(0.2126, 0.7152, 0.0722);

vec3 calculate_blinn_specular(vec3 light_dir, vec3 norm) {
	vec3 view_dir = normalize(view_position - frag_position);
	vec3 halfway_dir = normalize(light_dir + view_dir);
	float spec_base = max(dot(norm, halfway_dir), 0.0);

	return pow(spec_base, material.shininess) * material.specular;
}

vec3 calculate_point_light(PointLight light) {
	vec3 ambient = light.ambient * vec3(texture(material.diffuse_0, tex_coords));

	vec3 norm = normalize(normal);
	vec3 light_diff = light.position - frag_position;
	vec3 light_dir = normalize(light_diff);
	float distance = length(light_diff);

	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse_0, tex_coords));

	vec3 specular = light.specular * calculate_blinn_specular(norm, light_dir);

	// float attenuation;
	// if (full_attenuation) {
	// 	float linear = light.linear * distance;
	// 	float quadratic = light.quadratic * (distance * distance);
	// 	attenuation = 1.0 / (light.constant + linear + quadratic);
	// } else {
	// 	attenuation = gamma ? 1.0 / (distance * distance) : 1.0 / distance;
	// }

	float attenuation = 1.0 / (distance * distance);

	return ambient + (diffuse + specular) * attenuation;
}

void main() {
	vec3 result = vec3(0.0);
	float num_point_lights = clamp(num_point_lights, 0, MAX_NUM_POINT_LIGHTS);

	for (int i = 0; i < num_point_lights; i += 1) {
		result += calculate_point_light(point_lights[i]);
	}

	frag_color = vec4(result, 1.0);

	float brightness = dot(result, brightness_threshold);

	if (brightness > 1.0) {
		bright_color = frag_color;
	} else {
		bright_color = vec4(0.0, 0.0, 0.0, 1.0);
	}
}
