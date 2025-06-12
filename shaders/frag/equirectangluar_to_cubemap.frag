#version 330 core
out vec4 frag_color;

in vec3 world_position;

uniform sampler2D equirectangular_map;

const vec2 inv_atan = vec2(0.1591, 0.3183);

vec2 sample_spherical_map(vec3 v) {
	vec2 uv = vec2(atan(v.z, v.x), asin(v.y));
	uv = uv * inv_atan + 0.5;

	return uv;
}

void main() {
	vec2 uv = sample_spherical_map(normalize(world_position));
	vec3 color = texture(equirectangular_map, uv).rgb;

	frag_color = vec4(color, 1.0);
}
