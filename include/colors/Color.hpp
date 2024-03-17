#ifndef COLORS_COLOR_H
#define COLORS_COLOR_H

#include <glm/glm.hpp>

namespace Color {
struct Color {
    glm::vec3 ambient;
    glm::vec3 diffuse;
    glm::vec3 specular;

    Color(glm::vec3 _ambient, glm::vec3 _diffuse, glm::vec3 _specular)
        : ambient(_ambient), diffuse(_diffuse), specular(_specular) {}
};

const Color Black(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 0.0f, 0.0f));
const Color White(glm::vec3(0.2f, 0.2f, 0.2f), glm::vec3(0.5f, 0.5f, 0.5f), glm::vec3(1.0f, 1.0f, 1.0f));
const Color Red(glm::vec3(0.2f, 0.0f, 0.0f), glm::vec3(0.5f, 0.0f, 0.0f), glm::vec3(1.0f, 0.0f, 0.0f));
const Color Blue(glm::vec3(0.0f, 0.0f, 0.2f), glm::vec3(0.0f, 0.0f, 0.5f), glm::vec3(0.0f, 0.0f, 1.0f));
const Color Green(glm::vec3(0.0f, 0.2f, 0.0f), glm::vec3(0.0f, 0.5f, 0.0f), glm::vec3(0.0f, 1.0f, 0.0f));
const Color Purple(glm::vec3(0.2f, 0.0f, 0.2f), glm::vec3(0.5f, 0.0f, 0.5f), glm::vec3(1.0f, 0.0f, 1.0f));
const Color Yellow(glm::vec3(0.2f, 0.2f, 0.0f), glm::vec3(0.5f, 0.5f, 0.0f), glm::vec3(1.0f, 1.0f, 0.0f));
const Color Cyan(glm::vec3(0.0f, 0.2f, 0.2f), glm::vec3(0.0f, 0.5f, 0.5f), glm::vec3(0.0f, 1.0f, 1.0f));
const Color Orange(glm::vec3(0.2f, 0.1f, 0.0f), glm::vec3(0.5f, 0.25f, 0.0f), glm::vec3(1.0f, 0.5f, 0.0f));
} // namespace Color

#endif