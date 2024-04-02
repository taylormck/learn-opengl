#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aTexCoords;
layout(location = 3) in vec3 aTangent;
layout(location = 4) in vec3 aBitTangent;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat3 rotation;

out vec3 FragPosition;
out vec3 Normal;
out vec2 TexCoords;
out mat3 TBN;

void main() {
    FragPosition = vec3(model * vec4(aPos, 1.0));
    Normal = rotation * aNormal;
    TexCoords = aTexCoords;

    vec3 T = normalize(vec3(model * vec4(aTangent, 0.0)));
    vec3 B = normalize(vec3(model * vec4(aBitTangent, 0.0)));
    vec3 N = normalize(vec3(model * vec4(aNormal, 0.0)));
    TBN = mat3(T, B, N);

    gl_Position = projection * view * vec4(FragPosition, 1.0f);
}
