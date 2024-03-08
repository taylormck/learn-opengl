cmake_minimum_required(VERSION 3.22.1)

project(
    learn-opengl
    LANGUAGES CXX
)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "")

set(CMAKE_CXX_STANDARD 17)

set(APP_NAME app)

set(ENTRY_POINT main.cpp)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -xc++ -std=c++17 -Wall -Wextra -pedantic")

if (MINGW)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --target=x86_64-w64-windows-gnu -stdlib=libstdc++")
endif()

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
add_executable(${APP_NAME} ${ENTRY_POINT} ${GLAD_GL})

target_link_libraries(${APP_NAME} ${OPENGL_LIBRARIES} glfw)
