cmake_minimum_required(VERSION 3.22.1)
project(learn-opengl)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -Wall -Wextra -pedantic")

include_directories("include")

find_package(OpenGL REQUIRED)
include_directories(${OPENGL_INCLUDE_DIRS})

# Set up GLFW
set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GLFW_INSTALL OFF CACHE BOOL "GLFW lib only")
add_subdirectory(glfw)

# Set up GLAD
option(GLFW-CMAKE-STARTER-USE-GLFW-GLAD "Use GLAD from GLFW" ON)
include_directories("glfw/deps")
set(GLAD_GL "glfw/deps/glad/gl.h")

# Set up application
# set(MAIN_SRC main.cpp)
add_executable(app main.cpp ${GLAD_GL})

target_link_libraries(app ${OPENGL_LIBRARIES} glfw)
