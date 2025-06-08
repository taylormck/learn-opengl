#version 330 core
layout(location = 0) out vec3 g_position;
layout(location = 1) out vec3 g_normal;
layout(location = 2) out vec3 g_albedo_spec;

in vec3 frag_position;
in vec2 tex_coords;
in vec3 normal;

void main() {
	g_position = frag_position;
	g_normal = normalize(normal);
	g_albedo_spec = vec3(0.95);
}
