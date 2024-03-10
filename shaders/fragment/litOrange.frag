#version 330 core
out vec4 FragColor;

uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec3 lightPosition;
uniform vec3 viewPosition;

in vec3 fragPosition;
in vec3 normal;

float ambientStrength = 0.1f;
float specularStrength = 0.5f;

void main()
{
    vec3 unitNormal = normalize(normal);

    // Ambient lighting
    vec3 ambient = ambientStrength * lightColor;

    // Diffuse lighting
    vec3 lightDirection = normalize(lightPosition - fragPosition);
    float diff = max(dot(unitNormal, lightDirection), 0.0f);
    vec3 diffuse = diff * lightColor;

    // Specular lighting
    vec3 viewDirection = normalize(viewPosition - fragPosition);
    vec3 reflectDirection = reflect(-lightDirection, unitNormal);
    float shine = pow(max(dot(viewDirection, reflectDirection), 0.0f), 32);
    vec3 specular = specularStrength * shine * lightColor;

    vec3 result = (ambient + diffuse + specular) * objectColor;

    FragColor = vec4(result, 1.0);
}