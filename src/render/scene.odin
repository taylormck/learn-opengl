package render

import "../types"

Scene :: struct {
    meshes:              [dynamic]Mesh,

    // These correspond to filenames rather than the materials themselves.
    // The materials are stored in a global map so that they may be reused
    // acrosss multiple scenes.
    materials:           MaterialMap,
    vertices:            [dynamic]types.Vec4,
    texture_coordinates: [dynamic]types.Vec2,
    normals:             [dynamic]types.Vec3,
}

Mesh :: struct {}

scene_destroy :: proc(scene: ^Scene) {
    delete(scene.meshes)

    for key, &material in scene.materials do material_free(&material)
    delete(scene.materials)

    delete(scene.vertices)
    delete(scene.texture_coordinates)
    delete(scene.normals)
}
