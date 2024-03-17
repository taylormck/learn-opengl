/**
 * @file A camera interface that all cameras need to implement
 */

#ifndef CAMERA_H
#define CAMERA_H

#include <glm/glm.hpp>

class Camera {
public:
    virtual ~Camera(){};
    virtual glm::mat4 GetViewMatrix() const = 0;
    virtual float Zoom() const = 0;
    virtual glm::vec3 Position() const = 0;
    virtual glm::vec3 Front() const = 0;

    virtual void ProcessKeyboard(glm::vec3 direction, float deltaTime) = 0;
    virtual void ProcessMouseMovement(float xOffset, float yOffset, bool constrainPitch = true) = 0;
    virtual void ProcessMouseScroll(float yOffset) = 0;
};

#endif
