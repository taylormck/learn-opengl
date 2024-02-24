#version 330 core
out vec4 FragColor;

uniform float intensity;

void main() {
    FragColor = vec4(0.0f, intensity, 0.0f, 1.0f);
}
