#ifndef LIGHTS_POINT_LIGHT_H
#define LIGHTS_POINT_LIGHT_H

#include <glm/glm.hpp>

#include <colors/Color.hpp>

namespace Light {
struct Attenuation {
    float constant;
    float linear;
    float quadratic;

    Attenuation(const float _constant, const float _linear, const float _quadratic)
        : constant(_constant), linear(_linear), quadratic(_quadratic) {}
};

Attenuation BasicAttenuation = Attenuation(1.0f, 0.09f, 0.032f);

struct PointLight {
    Color::Color color;
    Attenuation attenuation;
    glm::vec3 position;

    PointLight(const Color::Color &_color, const Attenuation &_attenuation, const glm::vec3 &_position)
        : color(_color), attenuation(_attenuation), position(_position) {}
};
} // namespace Light

#endif