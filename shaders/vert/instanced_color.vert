#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 3) in vec3 aColor;

out vec3 vert_color;

uniform vec2 offsets[100];

void main() {
	vec2 offset = offsets[gl_InstanceID];
	gl_Position = vec4(aPos.xy / 10.0 + offset, 0.0, 1.0);
	vert_color = aColor;
}
