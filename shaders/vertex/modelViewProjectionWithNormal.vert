#version 330 core
layout(location=0)in vec3 aPos;
layout(location=1)in vec3 aNormal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat3 rotation;

out vec3 FragPosition;
out vec3 Normal;

void main()
{
    FragPosition = vec3(model * vec4(aPos, 1.0));
    Normal = rotation * aNormal;
    gl_Position = projection * view * vec4(FragPosition, 1.0f);
}
