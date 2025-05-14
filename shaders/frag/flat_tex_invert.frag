#version 330 core

out vec4 FragColor;

in vec2 tex_coords;

uniform sampler2D screen_texture;

void main() {
	vec3 tex_color = texture(screen_texture, tex_coords).xyz;
	tex_color = 1.0 - tex_color;
	FragColor = vec4(tex_color, 1.0);
}
