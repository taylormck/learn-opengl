#version 330 core

out vec4 FragColor;
in vec2 tex_coords;

uniform sampler2D screen_texture;

const float offset = 1.0 / 300.0;

const float one_over_sixteen = 1.0 / 16.0;
const float two_over_sixteen = 2.0 / 16.0;
const float four_over_sixteen = 4.0 / 16.0;

void main() {
	vec2 offsets[9] = vec2[](
		vec2(-offset, offset),	// top left
		vec2(0.0, offset),		// top center
		vec2(offset, offset),	// top right
		vec2(-offset, 0.0),		// center left
		vec2(0.0, 0.0),			// center center
		vec2(offset, 0.0),		// center right
		vec2(-offset, -offset), // bottom left
		vec2(0.0, -offset),		// bottom center
		vec2(offset, -offset)	// bottom right
	);

	// clang-format off
    float kernel[9] = float[](
		one_over_sixteen,  two_over_sixteen, one_over_sixteen,
		two_over_sixteen, four_over_sixteen, two_over_sixteen,
		one_over_sixteen,  two_over_sixteen, one_over_sixteen
    );
	// clang-format on

	vec3 sample_tex[9];
	for (int i = 0; i < 9; i += 1) {
		sample_tex[i] = vec3(texture(screen_texture, tex_coords.st + offsets[i]));
	}

	vec3 col = vec3(0.0);
	for (int i = 0; i < 9; i += 1) {
		col += sample_tex[i] * kernel[i];
	}

	FragColor = vec4(col, 1.0);
}
