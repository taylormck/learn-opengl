#version 330 core

struct Material {
	sampler2D diffuse;
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
in vec2 tex_coords;
in vec3 normal;

out vec4 FragColor;

uniform vec3 view_position;
uniform Material material;
uniform Light light;

void main() {
	vec3 diff_tex = vec3(texture(material.diffuse, tex_coords));
	vec3 ambient = light.ambient * diff_tex;

	vec3 norm = normalize(normal);
	vec3 light_dir = normalize(light.position - frag_position);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * diff_tex;

	vec3 view_dir = normalize(view_position - frag_position);
	vec3 halfway_dir = normalize(light_dir + view_dir);
	float spec = pow(max(dot(norm, halfway_dir), 0.0), material.shininess);
	vec3 specular = light.specular * spec * material.specular;

	vec3 result = ambient + diffuse + specular;
	FragColor = vec4(result, 1.0);
}
