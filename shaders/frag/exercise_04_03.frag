#version 330 core

out vec4 frag_color;

in vec3 our_color;
in vec2 tex_coords;

uniform sampler2D diffuse_0;
uniform sampler2D diffuse_1;

void main() {
	vec2 flipped_tex_coords = vec2(1.0 - tex_coords.x, tex_coords.y);
	frag_color = mix(texture(diffuse_0, tex_coords), texture(diffuse_1, flipped_tex_coords), 0.2);
}
