package render

import "../types"

Scene :: struct {
	meshes:    MeshMap,
	materials: MaterialMap,
	textures:  TextureMap,
}

MeshMap :: map[string]Mesh
TextureMap :: map[string]Texture

scene_destroy :: proc(scene: ^Scene) {
	for key, &mesh in scene.meshes do mesh_free(&mesh)
	delete(scene.meshes)

	for key, &material in scene.materials do material_free(&material)
	delete(scene.materials)
}
