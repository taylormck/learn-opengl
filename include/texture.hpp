#ifndef TEXTURE_H
#define TEXTURE_H

#include <string>

#include "openGLCommon.hpp"

struct Texture {
    GLuint ID;
    std::string Type;
    std::string Path;

    Texture(GLuint id, std::string type, std::string path) : ID(id), Type(type), Path(path) {}
};

#endif