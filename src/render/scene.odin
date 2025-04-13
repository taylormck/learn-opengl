package render

import "../types"

Scene :: struct {
    meshes:    [dynamic]Mesh,

    // These correspond to filenames rather than the materials themselves.
    // The materials are stored in a global map so that they may be reused
    // acrosss multiple scenes.
    materials: [dynamic]string,
    vertices:  [dynamic]types.Vec3,
}

Mesh :: struct {}

scene_destroy :: proc(scene: ^Scene) {
    delete(scene.meshes)
    delete(scene.materials)
}
