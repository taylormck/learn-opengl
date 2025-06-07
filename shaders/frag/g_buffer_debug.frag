#version 330 core
out vec4 frag_color;

in vec2 tex_coords;

uniform sampler2D g_position;
uniform sampler2D g_normal;
uniform sampler2D g_albedo_spec;

const int FRAG_POSITION = 0;
const int NORMAL = 1;
const int DIFFUSE = 2;
const int SPECULAR = 3;
const int SHININESS = 4;
const float max_shininess = 512.0;

uniform int channel;

void main() {
	frag_color = vec4(vec3(0.0), 1.0);

	switch (channel) {
	case FRAG_POSITION:
		frag_color.rgb = texture(g_position, tex_coords).rgb;
		break;
	case NORMAL:
		vec3 normal = texture(g_normal, tex_coords).rgb;

		if (normal.x == 0 && normal.y == 0 && normal.z == 0) {
			discard;
		}

		normal = normal * 0.5 + 0.5;
		frag_color.rgb = normal;
		break;
	case DIFFUSE:
		frag_color.rgb = texture(g_albedo_spec, tex_coords).rgb;
		break;
	case SPECULAR:
		frag_color.rgb = vec3(texture(g_albedo_spec, tex_coords).a);
		break;
	case SHININESS:
		float shininess = texture(g_position, tex_coords).a;
		shininess = shininess / (max_shininess + 1);
		shininess = pow(shininess, 1.0 / 2.2);
		frag_color.rgb = vec3(shininess);
		break;
	}
}
