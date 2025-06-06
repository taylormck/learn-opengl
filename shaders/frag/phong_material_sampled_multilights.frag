#version 330 core

struct Material {
	sampler2D diffuse_0;
	sampler2D specular_0;
	sampler2D normal_0;
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

struct DirectionalLight {
	vec3 direction;
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};

struct SpotLight {
	vec3 position;
	vec3 direction;
	float inner_cutoff;
	float outer_cutoff;
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

out vec4 FragColor;

uniform vec3 view_position;
uniform Material material;

#define MAX_NUM_POINT_LIGHTS 4
uniform int num_point_lights;

uniform PointLight point_lights[MAX_NUM_POINT_LIGHTS];
uniform DirectionalLight directional_light;
uniform SpotLight spot_light;

vec3 calculate_point_light(PointLight light) {
	vec3 ambient = light.ambient * vec3(texture(material.diffuse_0, tex_coords));

	vec3 norm = normalize(normal);
	vec3 light_diff = light.position - frag_position;
	vec3 light_dir = normalize(light_diff);
	float distance = length(light_diff);

	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse_0, tex_coords));

	vec3 specular = vec3(0.0);

	if (dot(norm, light_dir) > 0.0) {
		vec3 view_dir = normalize(view_position - frag_position);
		vec3 reflect_dir = reflect(-light_dir, norm);
		float spec = pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess);
		specular = light.specular * spec * texture(material.specular_0, tex_coords).rgb;
	}

	float linear = light.linear * distance;
	float quadratic = light.quadratic * distance * distance;
	float attenuation = 1.0 / (light.constant + linear + quadratic);

	return (ambient + diffuse + specular) * attenuation;
}

vec3 calculate_directional_light(DirectionalLight light) {
	vec3 ambient = light.ambient * vec3(texture(material.diffuse_0, tex_coords));

	vec3 norm = normalize(normal);
	vec3 light_dir = normalize(-light.direction);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse_0, tex_coords));

	vec3 specular = vec3(0.0);

	if (dot(norm, light_dir) > 0.0) {
		vec3 view_dir = normalize(view_position - frag_position);
		vec3 reflect_dir = reflect(-light_dir, norm);
		float spec = pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess);
		specular = light.specular * spec * texture(material.specular_0, tex_coords).rgb;
	}

	return ambient + diffuse + specular;
}

vec3 calculate_spot_light(SpotLight light) {
	vec3 ambient = light.ambient * vec3(texture(material.diffuse_0, tex_coords));

	vec3 light_diff = light.position - frag_position;
	vec3 light_dir = normalize(light_diff);
	float theta = dot(light_dir, normalize(-light.direction));
	float epsilon = light.inner_cutoff - light.outer_cutoff;
	float intensity = clamp((theta - light.outer_cutoff) / epsilon, 0.0, 1.0);

	vec3 norm = normalize(normal);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse_0, tex_coords));

	vec3 specular = vec3(0.0);

	if (dot(norm, light_dir) > 0.0) {
		vec3 view_dir = normalize(view_position - frag_position);
		vec3 reflect_dir = reflect(-light_dir, norm);
		float spec = pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess);
		specular = light.specular * spec * texture(material.specular_0, tex_coords).rgb;
	}

	float distance = length(light_diff);
	float linear = light.linear * distance;
	float quadratic = light.quadratic * (distance * distance);
	float attenuation = 1.0 / (light.constant + linear + quadratic);

	return (ambient + diffuse + specular) * attenuation * intensity;
}

void main() {
	vec3 result = vec3(0.0);
	float num_point_lights = min(num_point_lights, MAX_NUM_POINT_LIGHTS);

	for (int i = 0; i < num_point_lights; i += 1) {
		result += calculate_point_light(point_lights[i]);
	}

	result += calculate_directional_light(directional_light);
	result += calculate_spot_light(spot_light);

	FragColor = vec4(result, 1.0);
}
