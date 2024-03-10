#ifndef LIGHT_H
#define LIGHT_H

#include <glm/glm.hpp>

namespace Light {
    struct Light {
        glm::vec3 position;
        glm::vec3 ambient;
        glm::vec3 diffuse;
        glm::vec3 specular;
        glm::vec3 sourceColor;

        Light (
            glm::vec3 _position,
            glm::vec3 _ambient,
            glm::vec3 _diffuse,
            glm::vec3 _specular,
            glm::vec3 _sourceColor
        ):
            position(_position),
            ambient(_ambient),
            diffuse(_diffuse),
            specular(_specular),
            sourceColor(_sourceColor)
        {}
    };
}

#endif