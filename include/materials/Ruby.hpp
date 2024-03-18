#ifndef RUBY_H
#define RUBY_H

#include "materials/Material.hpp"
#include <glm/glm.hpp>


//  	0.1745 	0.01175 	0.01175 	0.61424 	0.04136 	0.04136 	0.727811 	0.626959
//  0.626959 	0.6
namespace Material {
inline Material Ruby = Material(
    glm::vec3(0.1745f, 0.01175f, 0.01175f),
    glm::vec3(0.61424f, 0.04136f, 0.04136f),
    glm::vec3(0.727811f, 0.626959f, 0.626959f),
    0.6f
);
}

#endif // RUBY_H