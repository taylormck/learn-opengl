#version 330 core

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    sampler2D emission;
    float shininess;
    float glow;
};

struct Light {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

out vec4 FragColor;

uniform Material material;
uniform Light light;
uniform vec3 viewPosition;

in vec3 FragPosition;
in vec3 Normal;
in vec2 TexCoords;

void main()
{
    vec3 unitNormal = normalize(Normal);
    vec3 sampledDiffuse = texture(material.diffuse, TexCoords).rgb;
    vec3 sampledSpecular = texture(material.specular, TexCoords).rgb;
    vec3 sampledEmission = texture(material.emission, TexCoords).rgb;

    // Ambient lighting
    vec3 ambient = light.ambient * sampledDiffuse;

    // Diffuse lighting
    vec3 lightDirection = normalize(light.position - FragPosition);
    float diff = max(dot(unitNormal, lightDirection), 0.0f);
    vec3 diffuse = light.diffuse * diff * sampledDiffuse;

    // Specular lighting
    vec3 viewDirection = normalize(viewPosition - FragPosition);
    vec3 reflectDirection = reflect(-lightDirection, unitNormal);
    float shine = pow(max(dot(viewDirection, reflectDirection), 0.0f), material.shininess);
    vec3 specular = light.specular * shine * sampledSpecular;

    vec3 emission = material.glow * sampledEmission;

    vec3 result = ambient + diffuse + specular + emission;

    FragColor = vec4(result, 1.0);
}