#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;

out vec2 tex_coords;

uniform mat4 transform;

void main() {
	vec2 position = vec2(transform * vec4(aPos.x, aPos.y, 0.0, 1.0));
	gl_Position = vec4(position, 0.0, 1.0);
	tex_coords = vec2(aTexCoord.x, 1.0 - aTexCoord.y);
}
