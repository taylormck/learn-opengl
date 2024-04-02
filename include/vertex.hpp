#ifndef VERTEX_H
#define VERTEX_H

#include <glm/glm.hpp>

struct Vertex {
    glm::vec3 Position;
    glm::vec3 Normal;
    glm::vec2 TextureCoordinates;
    glm::vec3 Tangent;
    glm::vec2 BitTangent;

    Vertex(
        glm::vec3 position,
        glm::vec3 normal,
        glm::vec2 textureCoordinates,
        glm::vec3 tangent,
        glm::vec3 bitTangent
    ) :
        Position(position),
        Normal(normal),
        TextureCoordinates(textureCoordinates),
        Tangent(tangent),
        BitTangent(bitTangent) {}
};

#endif
