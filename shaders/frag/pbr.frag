#version 330 core
out vec4 frag_color;

in VS_OUT {
	vec3 frag_position;
	vec3 normal;
	vec2 tex_coords;
}
fs_in;

void main() {
	frag_color = vec4(fs_in.normal, 1.0f);
}
