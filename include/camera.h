#ifndef CAMERA_H
#define CAMERA_H

#include <iostream>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include "openGLCommon.h"

constexpr float DEFAULT_YAW = -M_PI_2;
constexpr float DEFAULT_PITCH = 0.0f;
constexpr float DEFAULT_SPEED = 5.0f;
constexpr float DEFAULT_MOUSE_SENSITIVITY = 0.01f;
constexpr float DEFAULT_ZOOM = M_PI_4;
constexpr float DEFAULT_ZOOM_SENSITIVITY = 0.01f;

constexpr float cameraPitchLowerBoundary = -1.0f * M_PI_2 + 1.0f;
constexpr float cameraPitchUpperBoundary = M_PI_2 - 1.0f;

class Camera {
    public:
        glm::vec3 Position;
        glm::vec3 Front;
        glm::vec3 Up;
        glm::vec3 Right;
        glm::vec3 WorldUp;

        float Yaw;
        float Pitch;

        float MovementSpeed;
        float MouseSensitivity;
        float Zoom;
        float ZoomSensitivity;

        Camera(
            glm::vec3 position = glm::vec3(0.0f, 0.0f, 0.0f),
            glm::vec3 up = glm::vec3(0.0f, 1.0f, 0.0f),
            float yaw = DEFAULT_YAW,
            float pitch = DEFAULT_PITCH
        ): Front(glm::vec3(0.0f, 0.0f, -1.0f)), MovementSpeed(DEFAULT_SPEED),
        MouseSensitivity(DEFAULT_MOUSE_SENSITIVITY), Zoom(DEFAULT_ZOOM), ZoomSensitivity(DEFAULT_ZOOM_SENSITIVITY) {
            Position = position;
            WorldUp = glm::normalize(up);
            Yaw = yaw;
            Pitch = pitch;
            UpdateCameraVectors();
        }

        glm::mat4 GetViewMatrix() {
            return glm::lookAt(Position, Position + Front, Up);
        }

        void ProcessKeyboard(glm::vec3 direction, float deltaTime) {
            if (glm::dot(direction, direction)) {
                float velocity = MovementSpeed * deltaTime;
                Position += glm::normalize(direction) * velocity;
            }
        }

        void ProcessMouseMovement(float xOffset, float yOffset, GLboolean constrainPitch = true) {
            xOffset *= MouseSensitivity;
            yOffset *= MouseSensitivity;

            Yaw += xOffset;
            Pitch -= yOffset;

            if (constrainPitch) {
                Pitch = std::clamp(Pitch, cameraPitchLowerBoundary, cameraPitchUpperBoundary);
            }

            UpdateCameraVectors();
        }

        void ProcessMouseScroll(float yOffset) {
            Zoom = std::clamp(Zoom + (yOffset * ZoomSensitivity), glm::radians(1.0f), (float)M_PI_4);
        }

    private:
        void UpdateCameraVectors() {
            glm::vec3 front = glm::vec3(
                cos(Yaw) * cos(Pitch),
                sin(Pitch),
                sin(Yaw) * cos(Pitch)
            );

            Front = glm::normalize(front);
            Right = glm::normalize(glm::cross(Front, WorldUp));
            Up    = glm::normalize(glm::cross(Right, Front));
        }
};

#endif
