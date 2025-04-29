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

mesh_free :: proc(mesh: ^Mesh) {
    delete(mesh.vertices)
    delete(mesh.indices)
    delete(mesh.material)
}
