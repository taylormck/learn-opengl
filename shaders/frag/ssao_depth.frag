#version 330 core
// ssao_depth.frag
out float frag_color;

in vec2 tex_coords;

uniform sampler2D g_position;
uniform sampler2D g_normal;
uniform sampler2D noise;

#define MAX_KERNAL_SIZE 64
uniform int kernel_size;
uniform float radius;
uniform float bias;

uniform vec3 samples[MAX_KERNAL_SIZE];
uniform mat4 projection;

uniform float window_width;
uniform float window_height;

void main() {
	vec2 noise_scale = vec2(window_width / 4.0, window_height / 4.0);

	vec3 frag_pos = texture(g_position, tex_coords).xyz;

	vec3 normal = texture(g_normal, tex_coords).xyz;
	normal = normalize(normal);

	vec3 random_vec = texture(noise, tex_coords * noise_scale).xyz;
	random_vec = normalize(random_vec);

	vec3 tangent = normalize(random_vec - normal * dot(random_vec, normal));
	vec3 bitangent = cross(normal, tangent);
	mat3 tbn = mat3(tangent, bitangent, normal);

	float occlusion = 0.0;
	int kernel_size = clamp(kernel_size, 0, MAX_KERNAL_SIZE);
	float radius = clamp(radius, 0.1, 2.0);
	float bias = clamp(bias, 0.01, 0.1);

	for (int i = 0; i < kernel_size; i += 1) {
		vec3 sample_pos = tbn * samples[i];
		sample_pos = frag_pos + sample_pos * radius;

		vec4 offset = vec4(sample_pos, 1.0);
		offset = projection * offset;
		offset.xyz /= offset.w;
		offset.xyz = offset.xyz * 0.5 + 0.5;

		float sample_depth = texture(g_position, offset.xy).z;
		float range_check = smoothstep(0.0, 1.0, radius / abs(frag_pos.z - sample_depth));

		if (sample_depth >= sample_pos.z + bias) {
			occlusion += range_check;
		}
	}

	occlusion = 1.0 - (occlusion / kernel_size);
	frag_color = occlusion;
}
