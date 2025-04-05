#version 330 core

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
};

struct PointLight {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float constant;
    float linear;
    float quadratic;
};

struct DirectionalLight {
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct SpotLight {
    vec3 position;
    vec3 direction;
    float inner_cutoff;
    float outer_cutoff;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

in vec3 frag_position;
in vec2 tex_coords;
in vec3 normal;

out vec4 FragColor;

uniform vec3 view_position;
uniform Material material;

uniform PointLight point_light;
uniform DirectionalLight directional_light;
uniform SpotLight spot_light;

vec3 calculate_point_light(PointLight light) {
    vec3 ambient = point_light.ambient * vec3(texture(material.diffuse, tex_coords));

    vec3 norm = normalize(normal);
    vec3 light_diff = light.position - frag_position;
    vec3 light_dir = normalize(light_diff);
    float distance = length(light_diff);

    float diff = max(dot(norm, light_dir), 0.0);
    vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, tex_coords));

    vec3 view_dir = normalize(view_position - frag_position);
    vec3 reflect_dir = reflect(-light_dir, norm);
    float spec = pow(max(dot(view_dir, reflect_dir), 0), material.shininess);
    vec3 specular = light.specular * spec * vec3(texture(material.specular, tex_coords));

    float linear = light.linear * distance;
    float quadratic = light.quadratic * distance * distance;
    float attenuation = 1.0 / (light.constant + linear + quadratic);

    return (ambient + diffuse + specular) * attenuation;
}

vec3 calculate_direcitonal_light(DirectionalLight light) {
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, tex_coords));

    vec3 norm = normalize(normal);
    vec3 light_dir = normalize(-light.direction);
    float diff = max(dot(norm, light_dir), 0.0);
    vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, tex_coords));

    vec3 view_dir = normalize(view_position - frag_position);
    vec3 reflect_dir = reflect(-light_dir, norm);
    float spec = pow(max(dot(view_dir, reflect_dir), 0), material.shininess);
    vec3 specular = light.specular * spec * vec3(texture(material.specular, tex_coords));

    return ambient + diffuse + specular;
}

vec3 calculate_spot_light(SpotLight light) {
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, tex_coords));

    vec3 light_diff = light.position - frag_position;
    vec3 light_dir = normalize(light_diff);
    float theta = dot(light_dir, normalize(-light.direction));
    float epsilon = light.inner_cutoff - light.outer_cutoff;
    float intensity = clamp((theta - light.outer_cutoff) / epsilon, 0.0, 1.0);

    vec3 norm = normalize(normal);
    float diff = max(dot(norm, light_dir), 0.0);
    vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, tex_coords));

    vec3 view_dir = normalize(view_position - frag_position);
    vec3 reflect_dir = reflect(-light_dir, norm);
    float spec = pow(max(dot(view_dir, reflect_dir), 0), material.shininess);
    vec3 specular = light.specular * spec * vec3(texture(material.specular, tex_coords));

    return ambient + (diffuse + specular) * intensity;
}

void main() {
    vec3 result = vec3(0.0);

    result += calculate_point_light(point_light);
    result += calculate_direcitonal_light(directional_light);
    result += calculate_spot_light(spot_light);

    FragColor = vec4(result, 1.0);
}
