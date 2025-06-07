#version 330 core
layout(location = 0) out vec3 g_position;
layout(location = 1) out vec3 g_normal;
layout(location = 2) out vec4 g_albedo_spec;

in vec3 frag_position;
in vec3 normal;

void main() {
	g_position.rgb = frag_position;
	g_normal = normalize(normal); // Ignore the normal map for now.
	g_albedo_spec.rgb = vec3(0.95);
}
