package render

import "../types"

Scene :: struct {
	meshes:    MeshMap,
	materials: MaterialMap,
	textures:  TextureMap,
}

MeshMap :: map[string]Mesh
TextureMap :: map[string]Texture

scene_send_to_gpu :: proc(scene: ^Scene) {
	for _, &mesh in scene.meshes do mesh_send_to_gpu(&mesh)
}

scene_clear_from_gpu :: proc(scene: ^Scene) {
	for _, &mesh in scene.meshes do mesh_gpu_free(&mesh)
}

scene_draw :: proc(scene: ^Scene, shader: u32) {
	for _, &mesh in scene.meshes do mesh_draw(&mesh, shader)
}

scene_destroy :: proc(scene: ^Scene) {
	for key, &mesh in scene.meshes do mesh_free(&mesh)
	delete(scene.meshes)

	for key, &material in scene.materials do material_free(&material)
	delete(scene.materials)

	delete(scene.textures)
}
