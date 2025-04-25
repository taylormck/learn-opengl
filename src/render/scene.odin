package render

import "../types"

Scene :: struct {
    meshes:              MeshMap,
    materials:           MaterialMap,
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

Mesh :: struct {
    vertices:            [dynamic]types.Vec4,
    texture_coordinates: [dynamic]types.Vec2,
    normals:             [dynamic]types.Vec3,
    vao, vbo, ebo:       u32,
}

mesh_init :: proc() -> (mesh: Mesh) {
    return
}

mesh_free :: proc(mesh: ^Mesh) {}
