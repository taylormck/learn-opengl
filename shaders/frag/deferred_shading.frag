#version 330 core
out vec4 frag_color;

in vec2 tex_coords;

uniform sampler2D g_position;
uniform sampler2D g_normal;
uniform sampler2D g_albedo_spec;

struct Material {
	vec3 diffuse;
	float specular;
	float shininess;
};

struct GData {
	Material material;
	vec3 frag_position;
	vec3 normal;
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

const int MAX_NR_LIGHTS = 32;
uniform PointLight point_lights[MAX_NR_LIGHTS];
uniform int num_point_lights;

uniform vec3 view_position;

float calculate_blinn_specular(vec3 light_dir, GData g_data) {
	vec3 view_dir = normalize(view_position - g_data.frag_position);
	vec3 halfway_dir = normalize(light_dir + view_dir);
	float spec_base = max(dot(g_data.normal, halfway_dir), 0.0);

	return pow(spec_base, g_data.material.shininess) * g_data.material.specular;
}

vec3 calculate_point_light(PointLight light, GData g_data) {
	vec3 ambient = light.ambient * g_data.material.diffuse;

	vec3 light_diff = light.position - g_data.frag_position;
	vec3 light_dir = normalize(light_diff);
	float distance = length(light_diff);

	float diff = max(dot(g_data.normal, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * g_data.material.diffuse;

	vec3 specular = vec3(calculate_blinn_specular(light_dir, g_data));

	float linear = light.linear * distance;
	float quadratic = light.quadratic * (distance * distance);
	float attenuation = 1.0 / (light.constant + linear + quadratic);

	vec3 color = ambient + diffuse + specular;

	return color * attenuation;
}

void main() {
	// TODO: discard based on the normal to perserve background color
	vec3 normal = texture(g_normal, tex_coords).rgb;

	if (normal.x == 0 && normal.y == 0 && normal.z == 0) {
		discard;
	}

	vec4 g_position_data = texture(g_position, tex_coords);
	vec3 frag_position = g_position_data.rgb;

	vec4 g_albedo_data = texture(g_albedo_spec, tex_coords);

	GData g_data = GData(Material(g_albedo_data.rgb, g_albedo_data.a, g_position_data.a), frag_position, normal);

	vec3 result = vec3(0.0);

	int num_point_lights = clamp(num_point_lights, 0, MAX_NR_LIGHTS);
	for (int i = 0; i < num_point_lights; i += 1) {
		result += calculate_point_light(point_lights[i], g_data);
	}

	frag_color = vec4(result, 1.0);
}
