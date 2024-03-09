#version 330 core
out vec4 FragColor;

uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec3 lightPosition;

in vec3 FragPosition;
in vec3 Normal;

void main()
{
    float ambientStrength = 0.1f;
    vec3 ambient = ambientStrength * lightColor;

    vec3 normal = normalize(Normal);
    vec3 lightDirection = normalize(lightPosition - FragPosition);
    float diff = max(dot(normal, lightDirection), 0.0f);
    vec3 diffuse = diff * lightColor;

    vec3 result = (ambient + diffuse) * objectColor;

    FragColor = vec4(result, 1.0);
}