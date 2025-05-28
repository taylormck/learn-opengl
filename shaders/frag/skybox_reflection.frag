#version 330 core
out vec4 FragColor;

in vec3 frag_position;
in vec3 normal;

uniform vec3 view_position;
uniform samplerCube skybox;

void main() {
	vec3 I = normalize(frag_position - view_position);
	vec3 R = reflect(I, normalize(normal));
	FragColor = vec4(texture(skybox, R).rgb, 1.0);
}
