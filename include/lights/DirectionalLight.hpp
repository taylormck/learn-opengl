#ifndef LIGHTS_DIRECTIONAL_LIGHT_H
#define LIGHTS_DIRECTIONAL_LIGHT_H

#include <glm/glm.hpp>

#include <colors/Color.hpp>

namespace Light {
struct DirectionalLight {
    Color::Color color;
    glm::vec3 direction;

    DirectionalLight(const Color::Color &_color, const glm::vec3 &_direction) : color(_color), direction(_direction) {}
};
} // namespace Light

#endif