package render

import "../types"
import "core:log"
import "core:os"
import gl "vendor:OpenGL"

Scene :: struct {
    meshes:              MeshMap,
    materials:           MaterialMap,
    textures:            TextureMap,
    vertices:            [dynamic]types.Vec4,
    texture_coordinates: [dynamic]types.Vec2,
    normals:             [dynamic]types.Vec3,
}

scene_destroy :: proc(scene: ^Scene) {
    for key, &mesh in scene.meshes do mesh_free(&mesh)
    delete(scene.meshes)

    for key, &material in scene.materials do material_free(&material)
    delete(scene.materials)

    delete(scene.vertices)
    delete(scene.texture_coordinates)
    delete(scene.normals)
}

MeshMap :: map[string]Mesh

MeshVertex :: struct {
    position:            types.Vec3,
    texture_coordinates: types.Vec2,
    normal:              types.Vec3,
}

Mesh :: struct {
    vertices:      [dynamic]MeshVertex,
    indices:       [dynamic]types.Vec3u,
    material:      string,
    vao, vbo, ebo: u32,
}

mesh_init :: proc() -> (mesh: Mesh) {
    mesh.vertices = make([dynamic]MeshVertex)
    mesh.indices = make([dynamic]types.Vec3u)
    return
}

mesh_send_to_gpu :: proc(mesh: ^Mesh) {
    gl.GenVertexArrays(1, &mesh.vao)
    gl.GenBuffers(1, &mesh.vbo)
    gl.GenBuffers(1, &mesh.ebo)

    gl.BindVertexArray(mesh.vao)
    defer gl.BindVertexArray(0)

    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(
        gl.ARRAY_BUFFER,
        len(mesh.vertices) * size_of(MeshVertex),
        raw_data(mesh.vertices),
        gl.STATIC_DRAW,
    )

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
    gl.BufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        len(mesh.indices) * size_of(types.Vec3u),
        raw_data(mesh.indices),
        gl.STATIC_DRAW,
    )

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(
        0,
        3,
        gl.FLOAT,
        gl.FALSE,
        size_of(MeshVertex),
        offset_of(MeshVertex, position),
    )

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(
        1,
        2,
        gl.FLOAT,
        gl.FALSE,
        size_of(MeshVertex),
        offset_of(MeshVertex, texture_coordinates),
    )

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(
        2,
        3,
        gl.FLOAT,
        gl.FALSE,
        size_of(MeshVertex),
        offset_of(MeshVertex, normal),
    )
}

mesh_draw :: proc(mesh: ^Mesh) {
    gl.BindVertexArray(mesh.vao)
    defer gl.BindVertexArray(0)

    gl.DrawElements(gl.TRIANGLES, i32(len(mesh.indices)) * 3, gl.UNSIGNED_INT, nil)
}

mesh_gpu_free :: proc(mesh: ^Mesh) {
    gl.DeleteVertexArrays(1, &mesh.vao)
    gl.DeleteBuffers(1, &mesh.vbo)
    gl.DeleteBuffers(1, &mesh.ebo)
}

mesh_free :: proc(mesh: ^Mesh) {
    delete(mesh.vertices)
    delete(mesh.indices)
    delete(mesh.material)
}

TextureMap :: map[string]Texture

Texture :: struct {
    width, height, channels: i32,
    buffer:                  [^]u8,
}
