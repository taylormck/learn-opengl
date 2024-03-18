#ifndef MATERIAL_H
#define MATERIAL_H

#include <glm/glm.hpp>

namespace Material {
struct Material {
    glm::vec3 ambient;
    glm::vec3 diffuse;
    glm::vec3 specular;
    float shininess;

    Material(glm::vec3 _ambient, glm::vec3 _diffuse, glm::vec3 _specular, float _shininess) :
        ambient(_ambient), diffuse(_diffuse), specular(_specular), shininess(_shininess * 128.0f) {}
};
} // namespace Material

#endif // MATERIAL_H