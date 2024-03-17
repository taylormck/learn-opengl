#ifndef LIGHTS_POINT_LIGHT_H
#define LIGHTS_POINT_LIGHT_H

#include <glm/glm.hpp>

#include "colors/Color.hpp"
#include "lights/Attenuation.hpp"


namespace Light {

struct PointLight {
    Color::Color color;
    Attenuation attenuation;
    glm::vec3 position;

    PointLight(const Color::Color &_color, const Attenuation &_attenuation, const glm::vec3 &_position)
        : color(_color), attenuation(_attenuation), position(_position) {}
};
} // namespace Light

#endif