#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;
layout(location = 3) in vec3 aColor;

out vec3 our_color;
out vec2 tex_coords;

void main() {
	gl_Position = vec4(aPos, 1.0);
	our_color = aColor;
	tex_coords = aTexCoord;
}
