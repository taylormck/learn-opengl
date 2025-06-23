#version 330 core
out vec4 frag_color;

in vec3 position;
uniform sampler3D diffuse_0;
uniform float z_offset;

void main() {
	vec3 tex_coords = position * 0.5 + 0.5;
	tex_coords.z += z_offset;
	frag_color = texture(diffuse_0, tex_coords);
}
