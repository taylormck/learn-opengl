#version 330 core

out vec4 FragColor;

in vec2 tex_coords;

uniform sampler2D screen_texture;

float red_weight = 0.2126;
float green_weight = 0.7152;
float blue_weight = 0.0722;

void main() {
	vec3 tex_color = texture(screen_texture, tex_coords).xyz;
	float value = tex_color.r * red_weight + tex_color.g * green_weight + tex_color.b * blue_weight;
	FragColor = vec4(value, value, value, 1.0);
}
