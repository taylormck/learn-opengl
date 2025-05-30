#version 330 core
out vec4 frag_color;

struct Material {
	sampler2D diffuse_0;
	vec3 specular;
	float shininess;
};

struct DirectionalLight {
	vec3 direction;
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};

in VS_OUT {
	vec3 frag_position;
	vec3 normal;
	vec2 tex_coords;
	vec4 frag_position_light_space;
}
fs_in;

uniform vec3 view_position;
uniform Material material;
uniform DirectionalLight directional_light;
uniform sampler2D shadow_map;

float calculate_shadow_factor(vec4 frag_position_light_space) {
	vec3 shadow_coords = frag_position_light_space.xyz / frag_position_light_space.w;
	shadow_coords = shadow_coords * 0.5 + 0.5;

	float closest_depth = texture(shadow_map, shadow_coords.xy).r;
	float current_depth = shadow_coords.z;
	float shadow = current_depth > closest_depth ? 1.0 : 0.0;

	return shadow;
}

vec3 calculate_blinn_specular(vec3 light_dir, vec3 norm) {
	vec3 view_dir = normalize(view_position - fs_in.frag_position);
	vec3 halfway_dir = normalize(light_dir + view_dir);
	float spec_base = max(dot(norm, halfway_dir), 0.0);

	return pow(spec_base, material.shininess) * material.specular;
}

vec3 calculate_directional_light(DirectionalLight light) {
	vec3 diffuse_tex = texture(material.diffuse_0, fs_in.tex_coords).rgb;
	vec3 ambient = light.ambient * diffuse_tex;

	vec3 norm = normalize(fs_in.normal);
	vec3 light_dir = normalize(-light.direction);
	float diff = max(dot(norm, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * diffuse_tex;

	vec3 specular = light.specular * calculate_blinn_specular(norm, light_dir);

	float shadow = calculate_shadow_factor(fs_in.frag_position_light_space);
	return ambient + (1.0 - shadow) * (diffuse + specular);
}

void main() {
	frag_color = vec4(calculate_directional_light(directional_light), 1.0);
}
