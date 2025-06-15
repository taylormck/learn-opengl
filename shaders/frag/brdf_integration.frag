#version 330 core
out vec2 frag_color;

in vec2 tex_coords;

const float PI = 3.14159265359;
const uint SAMPLE_COUNT = 1024u;

float radical_inverse_vdc(uint bits) {
	bits = (bits << 16u) | (bits >> 16u);
	bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
	bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
	bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
	bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
	return float(bits) * 2.3283064365386963e-10; // 1.0 / 0x100000000
}

vec2 hammersly(uint i, uint n) {
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

// NOTE: we use a different value of k than the IBL calculation.
float geometry_schlick_ggx(float n_dot_v, float roughness) {
	float a = roughness;
	float k = (a * a) / 2.0;

	float nom = n_dot_v;
	float denom = n_dot_v * (1.0 - k) + k;

	return nom / denom;
}

float geometry_smith(vec3 n, vec3 v, vec3 l, float roughness) {
	float n_dot_v = max(dot(n, v), 0.0);
	float n_dot_l = max(dot(n, l), 0.0);

	float ggx2 = geometry_schlick_ggx(n_dot_v, roughness);
	float ggx1 = geometry_schlick_ggx(n_dot_l, roughness);

	return ggx1 * ggx2;
}

vec2 integrate_brdf(float n_dot_v, float roughness) {
	vec3 v = vec3(sqrt(1.0 - n_dot_v * n_dot_v), 0.0, n_dot_v);
	float a = 0.0;
	float b = 0.0;

	vec3 n = vec3(0.0, 0.0, 1.0);
	for (uint i = 0u; i < SAMPLE_COUNT; i += 1u) {
		vec2 xi = hammersly(i, SAMPLE_COUNT);
		vec3 h = importance_sample_ggx(xi, n, roughness);
		vec3 l = normalize(2.0 * dot(v, h) * h - v);

		float n_dot_l = max(l.z, 0.0);
		float n_dot_h = max(h.z, 0.0);
		float v_dot_h = max(dot(v, h), 0.0);

		if (n_dot_l > 0.0) {
			float g = geometry_smith(n, v, l, roughness);
			float g_vis = (g * v_dot_h) / (n_dot_h * n_dot_v);
			float fc = pow(1.0 - v_dot_h, 5.0);

			a += (1.0 - fc) * g_vis;
			b += fc * g_vis;
		}
	}

	a /= float(SAMPLE_COUNT);
	b /= float(SAMPLE_COUNT);

	return vec2(a, b);
}

void main() {
	vec2 integrated_brdf = integrate_brdf(tex_coords.x, tex_coords.y);
	frag_color = integrated_brdf;
}
