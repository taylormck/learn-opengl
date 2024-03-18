#ifndef LIGHTS_ATTENUATION_H
#define LIGHTS_ATTENUATION_H

namespace Light {
struct Attenuation {
    float constant;
    float linear;
    float quadratic;

    Attenuation(const float _constant, const float _linear, const float _quadratic) :
        constant(_constant), linear(_linear), quadratic(_quadratic) {}
};

Attenuation BasicAttenuation = Attenuation(1.0f, 0.09f, 0.032f);
} // namespace Light

#endif