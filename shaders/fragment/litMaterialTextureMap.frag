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

struct SpotLight {
    Color color;
    Attenuation attenuation;
    vec3 position;
    vec3 direction;
    float innerRadius;
    float outerRadius;
};

#define MAX_NUM_POINT_LIGHTS 4

out vec4 FragColor;

uniform Material material;
uniform DirectionalLight directionalLight;
uniform PointLight pointLights[MAX_NUM_POINT_LIGHTS];
uniform int numPointLights;
uniform SpotLight spotLight;
uniform vec3 viewPosition;

in vec3 FragPosition;
in vec3 Normal;
in vec2 TexCoords;

vec3 unitNormal;
vec3 sampledDiffuse;
vec3 sampledSpecular;

vec3 getLight(
    Color color,
    vec3 direction
) {

    // Ambient lighting
    vec3 ambient = color.ambient * sampledDiffuse;

    // Diffuse lighting
    vec3 unitDirection = normalize(direction);
    float diff = max(dot(unitNormal, unitDirection), 0.0f);
    vec3 diffuse = color.diffuse * diff * sampledDiffuse;

    // Specular lighting
    vec3 viewDirection = normalize(viewPosition - FragPosition);
    vec3 reflectDirection = reflect(-unitDirection, unitNormal);
    float shine = pow(max(dot(viewDirection, reflectDirection), 0.0f), material.shininess);
    vec3 specular = color.specular * shine * sampledSpecular;

    return ambient + diffuse + specular;
}

vec3 getDirectionalLight(DirectionalLight light) {
    return getLight(
        light.color,
        -light.direction
    );
}

vec3 getPointLight(PointLight light) {
    vec3 lightToPosition = light.position - FragPosition;
    vec3 rawLightValue = getLight(light.color, normalize(lightToPosition));

    float distance = length(lightToPosition);

    float attenuation = 1.0 / (
        light.attenuation.constant +
        light.attenuation.linear * distance +
        light.attenuation.quadratic * distance * distance
    );

    return rawLightValue * attenuation;
}

vec3 getSpotLight(SpotLight light) {
    vec3 lightToPosition = light.position - FragPosition;
    vec3 direction = normalize(lightToPosition);

    float theta = dot(direction, normalize(-light.direction));
    float epsilon = light.innerRadius - light.outerRadius;
    float intensity = clamp((theta - light.outerRadius) / epsilon, 0.0, 1.0);

    float distance = length(lightToPosition);

    float attenuation = 1.0 / (
        light.attenuation.constant +
        light.attenuation.linear * distance +
        light.attenuation.quadratic * distance * distance
    );

    return getLight(light.color, direction) * intensity * attenuation;
}

void main()
{
    unitNormal = normalize(Normal);
    sampledDiffuse = texture(material.diffuse, TexCoords).rgb;
    sampledSpecular = texture(material.specular, TexCoords).rgb;

    vec3 result = vec3(0.0);

    result += getDirectionalLight(directionalLight);
    result += getSpotLight(spotLight);

    for (int i = 0; i < numPointLights; ++i) {
        result += getPointLight(pointLights[i]);
    }

    FragColor = vec4(result, 1.0);
}