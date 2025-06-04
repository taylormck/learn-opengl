#version 330 core

layout(location = 0) out vec4 frag_color;
layout(location = 1) out vec4 bright_color;

uniform vec3 light_color;
const vec3 brightness_threshold = vec3(0.2126, 0.7152, 0.0722);

void main() {
	frag_color = vec4(light_color, 1.0);

	float brightness = dot(light_color, brightness_threshold);

	if (brightness > 1.0) {
		bright_color = frag_color;
	} else {
		bright_color = vec4(0.0, 0.0, 0.0, 1.0);
	}
}
