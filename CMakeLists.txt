cmake_minimum_required(VERSION 3.28.1)
project(learn-opengl)

find_package(OpenGL REQUIRED)

include_directories(${OPENGL_INCLUDE_DIRS})

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -Wall -Wextra -pedantic")

# Set up GLFW
set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GLFW_INSTALL OFF CACHE BOOL "GLFW lib only")
add_subdirectory(../glfw build)

# Set up GLAD
include_directories("${GLFW_SOUCE_DIR}/deps")
set(GLAD_GL "${GLFW_SOURCE_DIR}/deps/glad/gl.h")

add_executable(app WIN32 main.cpp ${GLAD_GL})

target_link_libraries(app ${OPENGL_LIBRARIES} glfw)
