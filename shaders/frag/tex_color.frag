#version 330 core

out vec4 frag_color;

in vec3 our_color;
in vec2 tex_coords;

uniform sampler2D diffuse_0;

void main() {
	frag_color = texture(diffuse_0, tex_coords) * vec4(our_color, 1.0f);
}
