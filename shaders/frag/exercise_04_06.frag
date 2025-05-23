#version 330 core

out vec4 frag_color;

in vec3 our_color;
in vec2 tex_coords;

uniform sampler2D diffuse_0;
uniform sampler2D diffuse_1;
uniform float ratio;

void main() {
	frag_color = mix(texture(diffuse_0, tex_coords), texture(diffuse_1, tex_coords), ratio);
}
