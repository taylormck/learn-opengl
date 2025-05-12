#version 330 core

struct Material {
	sampler2D diffuse_0;
	// sampler2D specular_0;
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

struct DirectionalLight {
	vec3 direction;
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};

in vec3 frag_position;
in vec2 tex_coords;
in vec3 normal;

out vec4 FragColor;

uniform vec3 view_position;
uniform Material material;

#define MAX_POINT_LIGHTS 4
uniform PointLight point_lights[MAX_POINT_LIGHTS];
uniform DirectionalLight directional_light;
uniform int num_point_lights;

vec4 tex_color;

vec3 calculate_point_light(PointLight light) {
	vec3 ambient = light.ambient * vec3(tex_color);

	vec3 norm = normalize(normal);
	vec3 light_diff = light.position - frag_position;
	vec3 light_dir = normalize(light_diff);
	float distance = length(light_diff);

	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(tex_color);

	// vec3 view_dir = normalize(view_position - frag_position);
	// vec3 reflect_dir = reflect(-light_dir, norm);
	// float spec = pow(max(dot(view_dir, reflect_dir), 0), material.shininess);
	// vec3 specular = light.specular * spec * vec3(texture(material.specular_0, tex_coords));

	float linear = light.linear * distance;
	float quadratic = light.quadratic * distance * distance;
	float attenuation = 1.0 / (light.constant + linear + quadratic);

	return (ambient + diffuse /* + specular */) * attenuation;
}

vec3 calculate_directional_light(DirectionalLight light) {
	vec3 ambient = light.ambient * vec3(tex_color);

	vec3 norm = normalize(normal);
	vec3 light_dir = normalize(-light.direction);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(tex_color);

	// vec3 view_dir = normalize(view_position - frag_position);
	// vec3 reflect_dir = reflect(-light_dir, norm);
	// float spec = pow(max(dot(view_dir, reflect_dir), 0), material.shininess);
	// vec3 specular = light.specular * spec * vec3(texture(material.specular_0, tex_coords));

	return ambient + diffuse /* + specular */;
}

void main() {
	tex_color = texture(material.diffuse_0, tex_coords);

	if (tex_color.a < 0.1) {
		discard;
	}

	vec3 result = vec3(0.0);

	for (int i = 0; i < num_point_lights; i += 1) {
		result += calculate_point_light(point_lights[i]);
	}

	result += calculate_directional_light(directional_light);

	FragColor = vec4(result, tex_color.a);
}
