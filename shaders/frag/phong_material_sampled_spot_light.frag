#version 330 core

struct Material {
	sampler2D diffuse_0;
	sampler2D specular_0;
	float shininess;
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

out vec4 frag_color;

uniform vec3 view_position;
uniform Material material;

uniform SpotLight spot_light;

vec3 calculate_spot_light(SpotLight light) {
	vec3 diffuse_tex = texture(material.diffuse_0, tex_coords).rgb;
	vec3 ambient = light.ambient * diffuse_tex;

	vec3 light_diff = light.position - frag_position;
	vec3 light_dir = normalize(light_diff);
	float theta = dot(light_dir, normalize(-light.direction));
	float epsilon = light.inner_cutoff - light.outer_cutoff;
	float intensity = clamp((theta - light.outer_cutoff) / epsilon, 0.0, 1.0);

	vec3 norm = normalize(normal);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * diffuse_tex;

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
	vec3 result = calculate_spot_light(spot_light);
	frag_color = vec4(result, 1.0);
}
