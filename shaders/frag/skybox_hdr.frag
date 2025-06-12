#version 330 core
out vec4 frag_color;

in vec3 tex_coords;

uniform samplerCube skybox;

void main() {
	vec3 env_color = texture(skybox, tex_coords).rgb;

	env_color = env_color / (env_color + vec3(1.0));
	env_color = pow(env_color, vec3(1.0 / 2.2));

	frag_color = vec4(env_color, 1.0);
}
