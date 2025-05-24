#version 330 core

struct Material {
	sampler2D diffuse;
	sampler2D specular;
	sampler2D emissive;
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

out vec4 frag_color;

uniform vec3 view_position;
uniform Material material;
uniform Light light;

void main() {
	vec3 ambient = light.ambient * vec3(texture(material.diffuse, tex_coords));

	vec3 norm = normalize(normal);
	vec3 light_dir = normalize(light.position - frag_position);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, tex_coords));

	vec3 view_dir = normalize(view_position - frag_position);
	vec3 reflect_dir = reflect(-light_dir, norm);
	float spec = pow(max(dot(view_dir, reflect_dir), 0), material.shininess);
	vec3 spec_tex = vec3(texture(material.specular, tex_coords));
	vec3 specular = light.specular * spec * spec_tex;

	vec3 emissive = vec3(0.0);
	if (spec_tex.x == 0.0 && spec_tex.y == 0.0 && spec_tex.z == 0.0) {
		emissive = vec3(texture(material.emissive, tex_coords));
	}

	vec3 result = ambient + diffuse + specular + emissive;
	frag_color = vec4(result, 1.0);
}
