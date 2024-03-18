#ifndef EMERALD_H
#define EMERALD_H

#include "materials/Material.hpp"
#include <glm/glm.hpp>


namespace Material {
inline Material Emerald = Material(
    glm::vec3(0.0215f, 0.1745f, 0.0215f),
    glm::vec3(0.07568f, 0.61424f, 0.07568f),
    glm::vec3(0.633f, 0.727811f, 0.633f),
    0.6f
);
}

#endif // EMERALD_H