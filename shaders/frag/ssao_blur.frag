#version 330 core
out float frag_color;

in vec2 tex_coords;

uniform sampler2D ssao_input;

void main() {
	vec2 texel_size = 1.0 / vec2(textureSize(ssao_input, 0));

	float result = 0.0;
	for (int x = -2; x <= 2; x += 1) {
		for (int y = -2; y <= 2; y += 1) {
			vec2 offset = vec2(float(x), float(y)) * texel_size;
			result += texture(ssao_input, tex_coords + offset).r;
		}
	}

	frag_color = result / 25.0;
}
