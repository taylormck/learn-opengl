#version 330 core
layout(location = 0) in vec3 aPos;

out vec3 world_position;

uniform mat4 projection_view;

void main() {
	world_position = aPos;
	gl_Position = projection_view * vec4(world_position, 1.0);
}
