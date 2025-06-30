package render

import "core:log"

Scene :: struct {
	meshes:    MeshMap,
	materials: MaterialMap,
	textures:  TextureMap,
}

MeshMap :: map[string]Mesh
TextureMap :: map[string]Texture

scene_send_to_gpu :: proc(scene: ^Scene, location := #caller_location) {
	log.info("Sending scene data to GPU", location)
	for _, &mesh in scene.meshes do mesh_send_to_gpu(&mesh)
}

scene_clear_from_gpu :: proc(scene: ^Scene, location := #caller_location) {
	log.info("Clearing scene data from GPU", location = location)
	for _, &mesh in scene.meshes do mesh_gpu_free(&mesh)
}

scene_draw_with_materials :: proc(scene: ^Scene, shader: u32) {
	ensure(shader != 0, "Attempted to draw scene with material with no shader")

	for _, &mesh in scene.meshes {
		mesh_set_material(&mesh, shader)
		mesh_draw(&mesh, shader)
	}
}

scene_draw :: proc(scene: ^Scene, shader: u32) {
	ensure(shader != 0, "Attempted to draw scene with no shader")
	for _, &mesh in scene.meshes do mesh_draw(&mesh, shader)
}

scene_draw_instanced :: proc(scene: ^Scene, shader: u32, num_instances: i32) {
	ensure(shader != 0, "Attempted to draw scene instances with no shader")
	ensure(num_instances > 0, "Attempted to draw scene instances with 0 or fewer instances")
	for _, &mesh in scene.meshes do mesh_draw_instanced(&mesh, shader, num_instances)
}

scene_draw_instanced_with_materials :: proc(
	scene: ^Scene,
	shader: u32,
	num_instances: i32,
	location := #caller_location,
) {
	ensure(shader != 0, "Attempted to draw scene instances with material with no shader")
	ensure(num_instances > 0, "Attempted to draw scene instances with material with 0 or fewer instances")

	for _, &mesh in scene.meshes {
		mesh_set_material(&mesh, shader)
		mesh_draw_instanced(&mesh, shader, num_instances)
	}
}

scene_destroy :: proc(scene: ^Scene, location := #caller_location) {
	log.info("Deleting scene data", location = location)

	for _, &mesh in scene.meshes do mesh_free(&mesh)
	delete(scene.meshes)

	for _, &material in scene.materials do material_free(&material)
	delete(scene.materials)

	delete(scene.textures)
}
