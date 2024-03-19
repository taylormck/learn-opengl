#ifndef MODEL_H
#define MODEL_H

#include <memory>
#include <string>
#include <vector>

#include <assimp/Importer.hpp>
#include <assimp/postprocess.h>
#include <assimp/scene.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include "assimp/material.h"
#include "assimp/mesh.h"
#include "mesh.hpp"
#include "shader.hpp"
#include "texture.hpp"

#include "openGLCommon.hpp"

namespace Model {
struct StbiImageDeleter {
    void operator()(unsigned char *data) { stbi_image_free(data); }
};

GLuint loadTexture(char const *path) {
    GLuint textureId;
    glGenTextures(1, &textureId);

    GLint width, height, nrComponents;

    std::unique_ptr<unsigned char, StbiImageDeleter> data(stbi_load(path, &width, &height, &nrComponents, 0));

    if (!data.get()) {
        std::cout << "Failed to load texture" << std::endl;
        return textureId;
    }

    GLenum format;

    switch (nrComponents) {
    case 1:
        format = GL_RED;
        break;
    case 3:
        format = GL_RGB;
        break;
    case 4:
        format = GL_RGBA;
        break;
    }

    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data.get());
    glGenerateMipmap(GL_TEXTURE_2D);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    return textureId;
};

class Model {
private:
    std::vector<Mesh> meshes;
    std::vector<Texture> loadedTextures;
    std::string directory;

    void loadModel(std::string path) {
        Assimp::Importer import;

        const aiScene *scene = import.ReadFile(path, aiProcess_Triangulate | aiProcess_FlipUVs);

        if (!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode) {
            std::cout << "ERROR::ASSIMP::" << import.GetErrorString() << "\n";
            return;
        }

        directory = path.substr(0, path.find_last_of('/'));

        processNode(scene->mRootNode, scene);
    }

    void processNode(aiNode *node, const aiScene *scene) {
        for (unsigned int i = 0; i < node->mNumMeshes; ++i) {
            aiMesh *mesh = scene->mMeshes[node->mMeshes[i]];
            processMesh(mesh, scene);
        }

        for (unsigned int i = 0; i < node->mNumChildren; ++i) {
            processNode(node->mChildren[i], scene);
        }
    }

    void processMesh(aiMesh *mesh, const aiScene *scene) {
        std::vector<Vertex> vertices;
        std::vector<GLuint> indices;
        std::vector<Texture> textures;

        for (unsigned int i = 0; i < mesh->mNumVertices; ++i) {
            aiVector3D aiVertex = mesh->mVertices[i];
            glm::vec3 position = glm::vec3(aiVertex.x, aiVertex.y, aiVertex.z);

            aiVector3D aiNormal = mesh->mNormals[i];
            glm::vec3 normal = glm::vec3(aiNormal.x, aiNormal.y, aiNormal.z);

            glm::vec2 textureCoordinates(0.0f, 0.0f);

            if (mesh->mTextureCoords[0]) {
                aiVector3D aiTextureCoordinates = mesh->mTextureCoords[0][i];
                textureCoordinates = glm::vec2(aiTextureCoordinates.x, aiTextureCoordinates.y);
            }

            vertices.emplace_back(position, normal, textureCoordinates);
        }

        for (unsigned int i = 0; i < mesh->mNumFaces; ++i) {
            aiFace face = mesh->mFaces[i];

            for (unsigned int j = 0; j < face.mNumIndices; j++) {
                indices.push_back(face.mIndices[j]);
            }
        }

        if (mesh->mMaterialIndex >= 0) {
            aiMaterial *material = scene->mMaterials[mesh->mMaterialIndex];
            std::vector<Texture> diffuseMaps = loadMaterialTextures(material, aiTextureType_DIFFUSE, "texture_diffuse");
            std::vector<Texture> specularMaps =
                loadMaterialTextures(material, aiTextureType_SPECULAR, "texture_specular");

            textures.insert(textures.end(), diffuseMaps.begin(), diffuseMaps.end());
            textures.insert(textures.end(), specularMaps.begin(), specularMaps.end());
        }

        meshes.emplace_back(vertices, indices, textures);
    }

    std::vector<Texture> loadMaterialTextures(aiMaterial *mat, aiTextureType type, std::string typeName) {
        std::vector<Texture> textures;

        for (unsigned int i = 0; i < mat->GetTextureCount(type); ++i) {
            aiString str;
            mat->GetTexture(type, i, &str);
            std::string path = directory + "/" + str.C_Str();

            auto matchingTexture =
                std::find_if(loadedTextures.begin(), loadedTextures.end(), [path](const Texture &loadedTexture) {
                    return path.compare(loadedTexture.Path) == 0;
                });

            if (matchingTexture != loadedTextures.end()) {
                textures.push_back(*matchingTexture);
            } else {
                loadedTextures.emplace_back(loadTexture(path.c_str()), typeName, path);
                textures.push_back(loadedTextures[loadedTextures.size() - 1]);
            }
        }

        return textures;
    }

public:
    Model(const char *path) { loadModel(path); }

    void Draw(Shader &shader) {
        for (const Mesh &mesh : meshes) {
            mesh.Draw(shader);
        }
    }
};
} // namespace Model

#endif
