#include <iostream>
#include <filesystem>
#include <math.h>

#define GLAD_GL_IMPLEMENTATION
#include <glad/gl.h>

#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>

#include "shader.h"

const unsigned int SCR_WIDTH = 800;
const unsigned int SCR_HEIGHT = 600;

void processInput(GLFWwindow* window) {
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
}

void framebuffer_size_callback(__attribute__((unused))GLFWwindow* window, int width, int height) {
    // make sure the viewport matches the new window dimensions; note that width and 
    // height will be significantly larger than specified on retina displays.
    glViewport(0, 0, width, height);
}

int main() {
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Taylor's Attempt to Learn OpenGL", NULL, NULL);

    if (!window) {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    if (!gladLoadGL(glfwGetProcAddress)) {
        std::cout << "Failed to load GLAD" << std::endl;
        return -1;
    }

    std::filesystem::path root = std::filesystem::current_path();
    std::string identityVertexShaderPath = root.string() + "/../shaders/vertex/identity.glsl";
    std::string upsideDownVertexShaderPath = root.string() + "/../shaders/vertex/upsideDown.glsl";
    std::string orangeFragmentShaderPath = root.string() + "/../shaders/fragment/orange.glsl";
    // std::string blueFragmentShaderPath = root.string() + "/../shaders/fragment/blue.glsl";
    std::string oscillatingGreenFragmentShaderPath = root.string() + "/../shaders/fragment/oscillatingGreen.glsl";

    Shader orangeShader(identityVertexShaderPath, orangeFragmentShaderPath);
    // Shader blueShader(upsideDownVertexShaderPath, blueFragmentShaderPath);
    Shader oscillatingGreenShader(upsideDownVertexShaderPath, oscillatingGreenFragmentShaderPath);


    float verticesLeft[] = {
        -0.9f, -0.5f, 0.0f,
        0.0f, -0.5f, 0.0f,
        -0.45f, 0.5f, 0.0f
    };

    float verticesRight[] = {
        0.0f, -0.5f, 0.0f,
        0.9f, -0.5f, 0.0f,
        0.45f, 0.5f, 0.0f
    };

    unsigned int VBOs[2], VAOs[2];
    glGenVertexArrays(2, VAOs);
    glGenBuffers(2, VBOs);

    glBindVertexArray(VAOs[0]);
    glBindBuffer(GL_ARRAY_BUFFER, VBOs[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(verticesLeft), verticesLeft, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    glBindVertexArray(VAOs[1]);
    glBindBuffer(GL_ARRAY_BUFFER, VAOs[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(verticesRight), verticesRight, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    // glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

    while (!glfwWindowShouldClose(window)) {
        processInput(window);

        // Render
        glClearColor(0.4f, 0.3f, 0.4f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        // Draw left triangle
        orangeShader.use();
        glBindVertexArray(VAOs[0]);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        // Draw right triangle
        float timeValue = glfwGetTime();
        float intensity = (sin(timeValue) / 2.0f) + 0.5f;

        int intensityUniformLocation = glGetUniformLocation(oscillatingGreenShader.id, "intensity");
        oscillatingGreenShader.use();
        glUniform1f(intensityUniformLocation, intensity);

        glBindVertexArray(VAOs[1]);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}
