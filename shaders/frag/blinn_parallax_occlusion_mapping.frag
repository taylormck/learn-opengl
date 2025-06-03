#version 330 core

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
	vec3 emissive;
	float constant;
	float linear;
	float quadratic;
};

in VS_OUT {
	vec3 frag_position;
	vec2 tex_coords;
	vec3 tangent_light_position;
	vec3 tangent_view_position;
	vec3 tangent_frag_position;
}
fs_in;

out vec4 frag_color;

uniform vec3 view_position;
uniform Material material;
uniform PointLight point_light;
uniform sampler2D normal_map;
uniform sampler2D depth_map;
uniform float height_scale;

const float min_layers = 8.0;
const float max_layers = 32.0;

vec2 parallax_mapping(vec2 tex_coords, vec3 view_dir) {
	float num_layers = mix(max_layers, min_layers, max(dot(vec3(0.0, 0.0, 1.0), view_dir), 0.0));
	float layer_depth = 1.0 / num_layers;
	float current_layer_depth = 0.0;
	vec2 p = view_dir.xy * height_scale;
	vec2 delta_tex_coords = p / num_layers;

	vec2 current_tex_coords = tex_coords;
	float current_depth_map_value = texture(depth_map, current_tex_coords).r;

	while (current_layer_depth < current_depth_map_value) {
		current_tex_coords -= delta_tex_coords;
		current_depth_map_value = texture(depth_map, current_tex_coords).r;
		current_layer_depth += layer_depth;
	}

	vec2 prev_tex_coords = current_tex_coords + delta_tex_coords;
	float after_depth = current_depth_map_value - current_layer_depth;
	float before_depth = texture(depth_map, prev_tex_coords).r - current_layer_depth + layer_depth;

	float weight = after_depth / (after_depth - before_depth);
	vec2 final_tex_coords = prev_tex_coords * weight + current_tex_coords * (1.0 - weight);

	return final_tex_coords;
}

vec3 calculate_blinn_specular(vec3 view_dir, vec3 light_dir, vec3 normal) {
	vec3 halfway_dir = normalize(light_dir + view_dir);
	float spec_base = max(dot(normal, halfway_dir), 0.0);

	return pow(spec_base, material.shininess) * material.specular;
}

vec3 calculate_point_light(PointLight light) {
	vec3 view_dir = normalize(fs_in.tangent_view_position - fs_in.tangent_frag_position);
	vec2 tex_coords = parallax_mapping(fs_in.tex_coords, view_dir);

	if (tex_coords.x > 1.0 || tex_coords.y > 1.0 || tex_coords.x < 0.0 || tex_coords.y < 0.0) {
		discard;
	}

	vec3 diffuse_tex = texture(material.diffuse_0, tex_coords).rgb;
	vec3 ambient = light.ambient * diffuse_tex;

	vec3 normal = texture(normal_map, tex_coords).rgb;
	normal = normalize(normal * 2.0 - 1.0);

	vec3 light_dir = normalize(fs_in.tangent_light_position - fs_in.tangent_frag_position);
	float distance = length(light.position - fs_in.frag_position);

	float diff = max(dot(normal, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * diffuse_tex;

	vec3 specular = light.specular * calculate_blinn_specular(view_dir, light_dir, normal);

	float linear = light.linear * distance;
	float quadratic = light.quadratic * (distance * distance);
	float attenuation = 1.0 / (light.constant + linear + quadratic);

	vec3 color = ambient + diffuse + specular;

	return color * attenuation;
}

void main() {
	vec3 result = calculate_point_light(point_light);
	frag_color = vec4(result, 1.0);
}
