#version 330 core
layout(location = 0) out vec3 g_position;
layout(location = 1) out vec3 g_normal;
layout(location = 2) out vec4 g_albedo_spec;

in vec2 tex_coords;
in vec3 frag_position;
in vec3 normal;

struct Material {
	sampler2D diffuse_0;
	sampler2D specular_0;
	sampler2D normal_0;
	float shininess;
};

uniform Material material;

void main() {
	g_position = frag_position;
	g_normal = normalize(normal);
	g_albedo_spec.rgb = texture(material.diffuse_0, tex_coords).rgb;
	g_albedo_spec.a = texture(material.specular_0, tex_coords).r;
}
