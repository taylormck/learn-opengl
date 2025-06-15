#version 330 core
out vec4 frag_color;

in vec3 world_position;

uniform samplerCube environment_map;
uniform float roughness;
uniform float cube_map_resolution;

const float PI = 3.14159265359;
const uint SAMPLE_COUNT = 1024u;

float radical_inverse_vdc(uint bits) {
	bits = (bits << 16u) | (bits >> 16u);
	bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
	bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
	bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
	bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);

	return float(bits) * 2.3283064365386963e-10; //  1.0 / 0x100000000
}

vec2 hammersley(uint i, uint n) {
	return vec2(float(i) / float(n), radical_inverse_vdc(i));
}

vec3 importance_sample_ggx(vec2 xi, vec3 n, float roughness) {
	float a = roughness * roughness;
	float phi = 2.0 * PI * xi.x;
	float cos_theta = sqrt((1.0 - xi.y) / (1.0 + (a * a - 1.0) * xi.y));
	float sin_theta = sqrt(1.0 - cos_theta * cos_theta);

	vec3 h = vec3(cos(phi) * sin_theta, sin(phi) * sin_theta, cos_theta);

	vec3 up = abs(n.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
	vec3 tangent = normalize(cross(up, n));
	vec3 bitangent = cross(n, tangent);

	vec3 sample_vec = tangent * h.x + bitangent * h.y + n * h.z;
	return normalize(sample_vec);
}

float distribution_ggx(float n_dot_h, float roughness) {
	float a = roughness * roughness;
	float a2 = a * a;

	float n_dot_h_2 = n_dot_h * n_dot_h;

	float nom = a2;
	float denom = n_dot_h_2 * (a2 - 1.0) + 1.0;
	denom = PI * denom * denom;

	return nom / denom;
}

void main() {
	vec3 n = normalize(world_position);
	vec3 r = n;
	vec3 v = r;

	float total_weight = 0.0;
	vec3 prefiltered_color = vec3(0.0);

	for (uint i = 0u; i < SAMPLE_COUNT; i += 1u) {
		vec2 xi = hammersley(i, SAMPLE_COUNT);
		vec3 h = importance_sample_ggx(xi, n, roughness);
		vec3 l = normalize(2.0 * dot(v, h) * h - v);

		float n_dot_l = max(dot(n, l), 0.0);

		if (n_dot_l > 0.0) {
			float n_dot_h = max(dot(n, h), 0.0);
			float h_dot_v = max(dot(h, v), 0.0);

			float d = distribution_ggx(n_dot_h, roughness);
			float pdf = d * n_dot_h / (4.0 * h_dot_v) + 0.0001;

			float sa_texel = 4.0 * PI / (6.0 * cube_map_resolution * cube_map_resolution);
			float sa_sample = 1.0 / (float(SAMPLE_COUNT) * pdf + 0.0001);

			float mip_level = roughness == 0.0 ? 0.0 : 0.5 * log2(sa_sample / sa_texel);

			prefiltered_color += texture(environment_map, l, mip_level).rgb * n_dot_l;
			total_weight += n_dot_l;
		}
	}

	prefiltered_color = prefiltered_color / total_weight;

	frag_color = vec4(prefiltered_color, 1.0);
}
