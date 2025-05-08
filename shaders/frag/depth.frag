#version 330 core
out vec4 FragColor;

float near = 0.1;
float far = 100.0;

float linearize_depth(float depth) {
    float ndc_z = depth * 2.0 - 1.0;

    return (2.0 * near) / (far + near - ndc_z * (far - near));
}

void main() {
    float depth = linearize_depth(gl_FragCoord.z);
    FragColor = vec4(vec3(depth * 10.0), 1.0);
}