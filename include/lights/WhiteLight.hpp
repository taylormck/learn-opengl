#ifndef WHITE_LIGHT_H
#define WHITE_LIGHT_H

#include <glm/glm.hpp>

#include "lights/Light.hpp"

namespace Light {
    struct WhiteLight: Light {
        static constexpr glm::vec3 ambient = glm::vec3(0.2f, 0.2f, 0.2f);
        static constexpr glm::vec3 diffuse = glm::vec3(0.5f, 0.5f, 0.5f);
        static constexpr glm::vec3 specular = glm::vec3(1.0f, 1.0f, 1.0f);
        static constexpr glm::vec3 sourceColor = glm::vec3(1.0f, 1.0f, 1.0f);

        WhiteLight (glm::vec3 _position) : Light(_position, ambient, diffuse, specular, sourceColor) {};
    };
}

#endif