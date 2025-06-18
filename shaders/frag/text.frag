#version 330 core
out vec4 frag_color;

in vec2 tex_coords;

uniform sampler2D alpha_01;

void main() {
	float alpha = texture(alpha_01, tex_coords).r;
	frag_color = vec4(0.5, 1.0, 1.0, alpha);
}
