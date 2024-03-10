#ifndef FLYING_CAMERA_H
#define FLYING_CAMERA_H

#include <algorithm>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include "camera/Camera.hpp"

class FlyingCamera: public Camera {
private:
    static constexpr float DEFAULT_YAW = -glm::half_pi<float>();
    static constexpr float DEFAULT_PITCH = 0.0f;
    static constexpr float DEFAULT_SPEED = 5.0f;
    static constexpr float DEFAULT_MOUSE_SENSITIVITY = 0.01f;
    static constexpr float DEFAULT_ZOOM = glm::quarter_pi<float>();
    static constexpr float DEFAULT_ZOOM_SENSITIVITY = 0.01f;
    static constexpr float CAMERA_PITCH_LOWER_BOUNDARY = 1.0f - glm::half_pi<float>();
    static constexpr float CAMERA_PITCH_UPPER_BOUNDARY = glm::half_pi<float>() - 1.0f;

    glm::vec3 _position;
    glm::vec3 _front;
    glm::vec3 _up;
    glm::vec3 _right;
    glm::vec3 _worldUp;

    float _yaw;
    float _pitch;

    float _movementSpeed;
    float _mouseSensitivity;

    float _zoom;
    float _zoomSensitivity;

    void UpdateCameraVectors() {
        glm::vec3 front = glm::vec3(
            cos(_yaw) * cos(_pitch),
            sin(_pitch),
            sin(_yaw) * cos(_pitch)
        );

        _front = glm::normalize(front);
        _right = glm::normalize(glm::cross(_front, _worldUp));
        _up    = glm::normalize(glm::cross(_right, _front));
    }

public:
    FlyingCamera(
        glm::vec3 position = glm::vec3(0.0f, 0.0f, 0.0f),
        glm::vec3 up = glm::vec3(0.0f, 1.0f, 0.0f),
        float yaw = DEFAULT_YAW,
        float pitch = DEFAULT_PITCH
    ): _front(glm::vec3(0.0f, 0.0f, -1.0f)), _movementSpeed(DEFAULT_SPEED),
    _mouseSensitivity(DEFAULT_MOUSE_SENSITIVITY), _zoom(DEFAULT_ZOOM), _zoomSensitivity(DEFAULT_ZOOM_SENSITIVITY) {
        _position = position;
        _worldUp = glm::normalize(up);
        _yaw = yaw;
        _pitch = pitch;
        UpdateCameraVectors();
    }

    ~FlyingCamera() {}

    glm::mat4 GetViewMatrix() const override {
        return glm::lookAt<float>(_position, _position + _front, _up);
    }

    float Zoom() const override {
        return _zoom;
    }

    glm::vec3 Position() const override {
        return _position;
    }

    void ProcessKeyboard(glm::vec3 direction, float deltaTime) override {
        if (glm::dot(direction, direction)) {
            float velocity = _movementSpeed * deltaTime;
            glm::vec3 newDirection = _right * direction.x + _front * direction.z;
            _position += glm::normalize(newDirection) * velocity;
        }
    }

    void ProcessMouseMovement(float xOffset, float yOffset, bool constrainPitch = true) override {
        xOffset *= _mouseSensitivity;
        yOffset *= _mouseSensitivity;

        _yaw = glm::mod(_yaw + xOffset, glm::tau<float>());
        _pitch -= yOffset;

        if (constrainPitch) {
            _pitch = std::clamp(_pitch - yOffset, CAMERA_PITCH_LOWER_BOUNDARY, CAMERA_PITCH_UPPER_BOUNDARY);
        }

        UpdateCameraVectors();
    }

    void ProcessMouseScroll(float yOffset) override {
        _zoom = std::clamp(_zoom + (yOffset * _zoomSensitivity), glm::radians(1.0f), glm::quarter_pi<float>());
    }
};

#endif
