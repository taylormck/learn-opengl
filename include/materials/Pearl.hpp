#ifndef PEARL_H
#define PEARL_H

#include <glm/glm.hpp>
#include "materials/Material.hpp"

namespace Material {
    inline Material Pearl = Material(
        glm::vec3(0.25f, 0.20725f, 0.20725f),
        glm::vec3(1.0f, 0.829f, 0.829f),
        glm::vec3(0.296648f, 0.296648f, 0.296648f),
        0.088f
    );
}

#endif // PEARL_H