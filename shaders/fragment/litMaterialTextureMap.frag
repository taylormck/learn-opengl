#version 330 core

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
};

struct Color {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct Attenuation {
    float constant;
    float linear;
    float quadratic;
};

struct DirectionalLight {
    Color color;
    vec3 direction;
};

struct PointLight {
    Color color;
    Attenuation attenuation;
    vec3 position;
};

out vec4 FragColor;

uniform Material material;
uniform DirectionalLight directionalLight;
uniform PointLight pointLight;
uniform vec3 viewPosition;

in vec3 FragPosition;
in vec3 Normal;
in vec2 TexCoords;

void main()
{
    vec3 unitNormal = normalize(Normal);
    vec3 sampledDiffuse = texture(material.diffuse, TexCoords).rgb;
    vec3 sampledSpecular = texture(material.specular, TexCoords).rgb;

    // Ambient lighting
    vec3 directionalAmbient = directionalLight.color.ambient * sampledDiffuse;

    // Diffuse lighting
    vec3 lightDirection = normalize(-directionalLight.direction);
    float diff = max(dot(unitNormal, lightDirection), 0.0f);
    vec3 directionalDiffuse = directionalLight.color.diffuse * diff * sampledDiffuse;

    // Specular lighting
    vec3 viewDirection = normalize(viewPosition - FragPosition);
    vec3 reflectDirection = reflect(-lightDirection, unitNormal);
    float shine = pow(max(dot(viewDirection, reflectDirection), 0.0f), material.shininess);
    vec3 directionalSpecular = directionalLight.color.specular * shine * sampledSpecular;

    vec3 directionalResult = directionalAmbient + directionalDiffuse + directionalSpecular;


    // Ambient lighting
    vec3 pointAmbient = pointLight.color.ambient * sampledDiffuse;

    // Diffuse lighting
    lightDirection = normalize(pointLight.position - FragPosition);
    diff = max(dot(unitNormal, lightDirection), 0.0f);
    vec3 pointDiffuse = directionalLight.color.diffuse * diff * sampledDiffuse;

    viewDirection = normalize(viewPosition - FragPosition);
    reflectDirection = reflect(-lightDirection, unitNormal);
    shine = pow(max(dot(viewDirection, reflectDirection), 0.0f), material.shininess);
    vec3 pointSpecular = directionalLight.color.specular * shine * sampledSpecular;

    float distance = length(pointLight.position - FragPosition);
    float attenuation = 1.0 / (
        pointLight.attenuation.constant +
        pointLight.attenuation.linear * distance +
        pointLight.attenuation.quadratic * distance * distance
    );

    vec3 pointResult = (pointAmbient + pointDiffuse + pointSpecular) * attenuation;

    vec3 result = directionalResult + pointResult;

    FragColor = vec4(result, 1.0);
}