#version 330 core
out vec4 frag_color;

in vec2 tex_coords;

uniform sampler2D diffuse_0;

void main() {
	float tex_color = texture(diffuse_0, tex_coords).r;

	frag_color = vec4(vec3(tex_color), 1.0);
}
