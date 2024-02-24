#version 330 core
out vec4 FragColor;

in vec4 position;

void main()
{
    FragColor=position + vec4(0.5f, 0.5f, 0.0f, 0.0f);
}
