#version 330 core

struct Material {
	sampler2D diffuse_0;
	sampler2D specular_0;
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

out vec4 frag_color;

uniform vec3 view_position;
uniform Material material;

uniform PointLight point_light;

vec3 calculate_point_light(PointLight light) {
	vec3 diffuse_tex = texture(material.diffuse_0, tex_coords).rgb;
	vec3 ambient = light.ambient * diffuse_tex;

	vec3 norm = normalize(normal);
	vec3 light_diff = light.position - frag_position;
	vec3 light_dir = normalize(light_diff);
	float distance = length(light_diff);

	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * diffuse_tex;

	vec3 specular = vec3(0.0);

	if (dot(normal, light_dir) > 0.0) {
		vec3 view_dir = normalize(view_position - frag_position);
		vec3 reflect_dir = reflect(-light_dir, norm);
		float spec = pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess);
		vec3 specular = light.specular * spec * texture(material.specular_0, tex_coords).rgb;
	}

	float linear = light.linear * distance;
	float quadratic = light.quadratic * (distance * distance);
	float attenuation = 1.0 / (light.constant + linear + quadratic);

	return (ambient + diffuse + specular) * attenuation;
}

void main() {
	vec3 result = calculate_point_light(point_light);
	frag_color = vec4(result, 1.0);
}
