#version 330 core

uniform vec4 our_color;
out vec4 frag_color;

void main() {
	frag_color = our_color;
}
