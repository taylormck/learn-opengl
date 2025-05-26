#version 330 core

out vec4 frag_color;

float near = 0.1;
float far = 100.0;
float two_near_far = near * far * 2.0;

float linearize_depth(float depth) {
	float ndc_z = depth * 2.0 - 1.0;

	return two_near_far / (far + near - ndc_z * (far - near));
}

void main() {
	float depth = linearize_depth(gl_FragCoord.z) / far;
	frag_color = vec4(vec3(depth * 10.0), 1.0);
}
