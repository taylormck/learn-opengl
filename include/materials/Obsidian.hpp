#ifndef OBSIDIAN_H
#define OBSIDIAN_H

#include "materials/Material.hpp"
#include <glm/glm.hpp>


namespace Material {
inline Material Obsidian = Material(
    glm::vec3(0.05375f, 0.05f, 0.06625f),
    glm::vec3(0.18275f, 0.17f, 0.22525f),
    glm::vec3(0.332741f, 0.328634f, 0.346435f),
    0.3f
);
}

#endif // OBSIDIAN_H