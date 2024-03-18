#ifndef LIGHTS_SPOT_LIGHT_H
#define LIGHTS_SPOT_LIGHT_H

#include <glm/glm.hpp>

#include "colors/Color.hpp"
#include "lights/Attenuation.hpp"

namespace Light {
struct SpotLight {
    Color::Color color;
    Attenuation attenuation;
    glm::vec3 position;
    glm::vec3 direction;
    float innerRadius;
    float outerRadius;

    SpotLight(
        const Color::Color &_color,
        const Attenuation &_attenuation,
        const glm::vec3 &_position,
        const glm::vec3 &_direction,
        const float _innerRadius,
        const float _outerRadius
    ) :
        color(_color),
        attenuation(_attenuation),
        position(_position),
        direction(_direction),
        innerRadius(_innerRadius),
        outerRadius(_outerRadius) {}
};
} // namespace Light

#endif