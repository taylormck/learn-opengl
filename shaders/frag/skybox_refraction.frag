#version 330 core
out vec4 FragColor;

in vec3 frag_position;
in vec3 normal;

uniform vec3 camera_position;
uniform samplerCube skybox;

const float air_index = 1.0;
const float water_index = 1.33;
const float ice_index = 1.309;
const float glass_index = 1.52;
const float diamond = 2.42;

void main() {
	float ratio = air_index / diamond;
	vec3 I = normalize(frag_position - camera_position);
	vec3 R = refract(I, normalize(normal), ratio);

	FragColor = vec4(texture(skybox, R).rgb, 1.0);
}
