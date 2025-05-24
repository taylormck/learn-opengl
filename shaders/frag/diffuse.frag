#version 330 core

struct Material {
	vec3 ambient;
	vec3 diffuse;
};

struct Light {
	vec3 position;
	vec3 ambient;
	vec3 diffuse;
};

in vec3 frag_position;
in vec3 normal;

out vec4 frag_color;

uniform Material material;
uniform Light light;

float ambient_factor = 0.1;

void main() {
	vec3 ambient = ambient_factor * light.ambient * material.ambient;

	vec3 norm = normalize(normal);
	vec3 light_dir = normalize(light.position - frag_position);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = diff * light.diffuse * material.diffuse * (1.0 - ambient_factor);

	vec3 result = ambient + diffuse;

	frag_color = vec4(diffuse, 1.0);
}
