#version 330 core

struct Material {
    sampler2D texture_diffuse0;
    sampler2D texture_diffuse1;
    sampler2D texture_diffuse2;
    sampler2D texture_specular0;
    sampler2D texture_specular1;
    sampler2D texture_normal0;
    sampler2D texture_normal1;
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

uniform mat3 rotation;

in vec3 FragPosition;
in vec3 Normal;
in vec2 TexCoords;

vec3 unitNormal;
vec3 sampledDiffuse;
vec3 sampledSpecular;
vec3 sampledNormal;

vec3 getLight(Color color, vec3 direction) {
    // Ambient lighting
    vec3 ambient = color.ambient * sampledDiffuse;

    // Diffuse lighting
    vec3 unitDirection = normalize(direction);
    float diff = max(dot(unitNormal, unitDirection), 0.0f);
    vec3 diffuse = color.diffuse * diff * sampledDiffuse;

    // Specular lighting
    vec3 viewDirection = normalize(viewPosition - FragPosition);
    vec3 halfway = normalize(direction + viewDirection);
    float shine = pow(max(dot(unitNormal, halfway), 0.0f), material.shininess);
    vec3 specular = color.specular * shine * sampledSpecular;

    return ambient + diffuse + specular;
}

float getAttenuation(Attenuation attenuation, float distance) {
    float denominator = attenuation.constant;
    denominator += attenuation.linear * distance;
    denominator += attenuation.linear * distance * distance;

    return 1.0 / denominator;
}

vec3 getDirectionalLight(DirectionalLight light) { return getLight(light.color, -light.direction); }

vec3 getPointLight(PointLight light) {
    vec3 lightToPosition = light.position - FragPosition;
    vec3 direction = normalize(lightToPosition);
    float distance = length(lightToPosition);

    vec3 rawLightValue = getLight(light.color, direction);
    float attenuation = getAttenuation(light.attenuation, distance);

    return rawLightValue * attenuation;
}

vec3 getSpotLight(SpotLight light) {
    vec3 lightToPosition = light.position - FragPosition;
    vec3 direction = normalize(lightToPosition);
    float distance = length(lightToPosition);

    float theta = dot(direction, normalize(-light.direction));
    float epsilon = light.innerRadius - light.outerRadius;
    float intensity = clamp((theta - light.outerRadius) / epsilon, 0.0, 1.0);

    vec3 rawLightValue = getLight(light.color, direction);
    float attenuation = getAttenuation(light.attenuation, distance);

    return rawLightValue * intensity * attenuation;
}

void main() {
    sampledDiffuse = texture(material.texture_diffuse0, TexCoords).rgb;
    sampledSpecular = texture(material.texture_specular0, TexCoords).rgb;
    sampledNormal = rotation * texture(material.texture_normal0, TexCoords).rgb;
    unitNormal = normalize(sampledNormal);

    vec3 result = vec3(0.0);

    result += getDirectionalLight(directionalLight);
    result += getSpotLight(spotLight);

    for (int i = 0; i < numPointLights; ++i) {
        result += getPointLight(pointLights[i]);
    }

    FragColor = vec4(result, 1.0);
}
