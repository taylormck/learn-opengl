#version 330 core
out vec4 frag_color;

in vec3 position;
uniform sampler3D diffuse_0;

void main() {
	vec3 tex_coords = position * 0.5 + 0.5;
	frag_color = texture(diffuse_0, tex_coords);
}
