#version 330 core
out vec4 frag_color;

struct Material {
	sampler2D diffuse_0;
	vec3 specular;
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

in VS_OUT {
	vec3 frag_position;
	vec3 normal;
	vec2 tex_coords;
}
fs_in;

uniform vec3 view_position;
uniform Material material;
uniform PointLight point_light;
uniform float far_plane;
uniform samplerCube depth_map;
uniform bool debug;

const float bias = 0.05;

float calculate_shadow_factor(PointLight light, vec3 frag_position) {
	vec3 frag_to_light = frag_position - light.position;
	float closest_depth = texture(depth_map, frag_to_light).r;

	if (debug) {
		return closest_depth;
	}

	closest_depth *= far_plane;
	float current_depth = length(frag_to_light);
	float shadow = current_depth - bias > closest_depth ? 1.0 : 0.0;

	return shadow;
}

vec3 calculate_blinn_specular(vec3 light_dir, vec3 normal) {
	vec3 view_dir = normalize(view_position - fs_in.frag_position);
	vec3 halfway_dir = normalize(light_dir + view_dir);
	float spec_base = max(dot(normal, halfway_dir), 0.0);

	return pow(spec_base, material.shininess) * material.specular;
}

vec3 calculate_point_light(PointLight light) {
	float shadow = calculate_shadow_factor(light, fs_in.frag_position);

	if (debug) {
		return vec3(shadow);
	}

	vec3 diffuse_tex = texture(material.diffuse_0, fs_in.tex_coords).rgb;
	vec3 ambient = light.ambient * diffuse_tex;

	vec3 normal = normalize(fs_in.normal);

	vec3 light_diff = light.position - fs_in.frag_position;
	vec3 light_dir = normalize(light_diff);
	float distance = length(light_diff);

	float diff = max(dot(normal, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * diffuse_tex;

	vec3 specular = calculate_blinn_specular(light_dir, normal);

	float linear = light.linear * distance;
	float quadratic = light.quadratic * (distance * distance);
	float attenuation = 1.0 / (light.constant + linear + quadratic);

	vec3 color = ambient + (1.0 - shadow) * (diffuse + specular);

	return color * attenuation;
}

void main() {
	frag_color = vec4(calculate_point_light(point_light), 1.0);
}
