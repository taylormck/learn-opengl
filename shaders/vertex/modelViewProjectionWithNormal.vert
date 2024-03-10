#version 330 core
layout(location=0)in vec3 aPos;
layout(location=1)in vec3 aNormal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat4 rotation;

out vec3 fragPosition;
out vec3 normal;

void main()
{
    fragPosition = vec3(model * vec4(aPos, 1.0));

    mat3 rotation = transpose(inverse(mat3(model)));
    normal = rotation * aNormal;

    gl_Position = projection * view * vec4(fragPosition, 1.0f);
}
