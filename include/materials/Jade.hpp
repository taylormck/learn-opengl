#ifndef JADE_H
#define JADE_H

#include <glm/glm.hpp>
#include "materials/Material.hpp"

namespace Material {
    inline Material Jade = Material(
        glm::vec3(0.135f, 0.2225f, 0.1575f),
        glm::vec3(0.54f, 0.89f, 0.63f),
        glm::vec3(0.316228f, 0.316228f, 0.316228f),
        0.1f
    );
}

#endif // JADE_H