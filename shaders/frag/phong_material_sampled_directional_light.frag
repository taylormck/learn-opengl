#version 330 core

struct Material {
	sampler2D diffuse_0;
	sampler2D specular_0;
	sampler2D normal_0;
	float shininess;
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

out vec4 frag_color;

uniform vec3 view_position;
uniform Material material;
uniform DirectionalLight directional_light;

vec3 calculate_directional_light(DirectionalLight light) {
	vec3 diffuse_tex = texture(material.diffuse_0, tex_coords).rgb;
	vec3 ambient = light.ambient * diffuse_tex;

	vec3 norm = normalize(normal);
	vec3 light_dir = normalize(-light.direction);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * diffuse_tex;

	vec3 view_dir = normalize(view_position - frag_position);
	vec3 reflect_dir = reflect(-light_dir, norm);
	float spec = pow(max(dot(view_dir, reflect_dir), 0), material.shininess);
	vec3 specular = light.specular * spec * vec3(texture(material.specular_0, tex_coords));

	return ambient + diffuse + specular;
}

void main() {
	vec3 result = calculate_directional_light(directional_light);
	frag_color = vec4(result, 1.0);
}
