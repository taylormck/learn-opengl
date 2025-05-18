#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 3) in vec3 aColor;
layout(location = 4) in vec2 aOffset;

out vec3 vert_color;

void main() {
	vec2 pos = aPos.xy / 10.0 * (gl_InstanceID / 100.0);
	gl_Position = vec4(pos + aOffset, 0.0, 1.0);
	vert_color = aColor;
}
