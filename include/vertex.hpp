#ifndef VERTEX_H
#define VERTEX_H

#include <glm/glm.hpp>

struct Vertex {
    glm::vec3 Position;
    glm::vec3 Normal;
    glm::vec2 TextureCoordinates;

    Vertex(glm::vec3 position, glm::vec3 normal, glm::vec2 textureCoordinates):
    Position(position), Normal(normal), TextureCoordinates(textureCoordinates) {}
};

#endif