#version 330 core

struct Material {
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
	float shininess;
};

struct Light {
	vec3 position;
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};

in vec3 frag_position;
in vec3 normal;

out vec4 frag_color;

uniform vec3 view_position;
uniform Material material;
uniform Light light;

void main() {
	vec3 ambient = material.ambient * light.ambient;

	vec3 norm = normalize(normal);
	vec3 light_dir = normalize(light.position - frag_position);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = diff * material.diffuse * light.diffuse;

	vec3 view_dir = normalize(view_position - frag_position);
	vec3 reflect_dir = reflect(-light_dir, norm);
	float spec = pow(max(dot(view_dir, reflect_dir), 0), material.shininess);
	vec3 specular = spec * material.specular * light.specular;

	vec3 result = ambient + diffuse + specular;
	frag_color = vec4(result, 1.0);
}
