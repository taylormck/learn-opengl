#version 330 core
out vec4 frag_color;

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
	float constant;
	float linear;
	float quadratic;
};

in vec3 frag_position;
in vec2 tex_coords;
in vec3 normal;

uniform bool gamma;
uniform vec3 view_position;
uniform Material material;

#define MAX_NUM_POINT_LIGHTS 4
uniform int num_point_lights;

uniform PointLight point_lights[MAX_NUM_POINT_LIGHTS];

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

	float attenuation = gamma ? 1.0 / (distance * distance) : 1.0 / distance;

	return (ambient + diffuse + specular) * attenuation;
}

void main() {
	vec3 result = vec3(0.0);
	float num_point_lights = clamp(num_point_lights, 0, MAX_NUM_POINT_LIGHTS);

	for (int i = 0; i < num_point_lights; i += 1) {
		result += calculate_point_light(point_lights[i]);
	}

	if (gamma) {
		result = pow(result, vec3(1.0 / 2.2));
	}

	frag_color = vec4(result, 1.0);
}
