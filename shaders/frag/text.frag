#version 330 core
out vec4 frag_color;

in vec2 tex_coords;

uniform sampler2D alpha_01;
uniform vec3 color;

void main() {
	float alpha = texture(alpha_01, tex_coords).r;
	frag_color = vec4(color, alpha);
}
