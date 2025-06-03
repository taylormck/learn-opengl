#version 330 core
out vec4 frag_color;

in vec2 tex_coords;

uniform sampler2D hdr_buffer;
uniform bool hdr;

const float gamma = 2.2;
uniform bool linearize;
uniform bool reinhard;
uniform float exposure;

void main() {
	vec3 hdr_color = texture(hdr_buffer, tex_coords).rgb;

	// If the hdr_color is gamma corrected already, we need to linearize it.
	if (linearize) {
		hdr_color = pow(hdr_color, vec3(2.2));
	}

	vec3 result;

	if (hdr && reinhard) {
		vec3 mapped = hdr_color / (hdr_color + vec3(1.0));
		result = pow(mapped, vec3(1.0 / gamma));
	} else if (hdr) {
		vec3 mapped = vec3(1.0) - exp(-hdr_color * exposure);
		result = pow(mapped, vec3(1.0 / gamma));
		;
	} else {
		result = pow(hdr_color, vec3(1.0 / gamma));
	}

	frag_color = vec4(result, 1.0);
}
