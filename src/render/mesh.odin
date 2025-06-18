package render

import "../shaders"
import "../types"
import "../utils"
import "core:fmt"
import "core:log"
import "core:os"
import gl "vendor:OpenGL"

Mesh :: struct {
	vertices:      [dynamic]MeshVertex,
	indices:       [dynamic]types.Vec3u,
	material_name: string,
	material:      Material,
	vao, vbo, ebo: u32,
	transform_vbo: u32,
	textures:      [dynamic]Texture,
}

MeshVertex :: struct {
	position:            types.Vec3,
	texture_coordinates: types.Vec2,
	normal:              types.Vec3,
}

mesh_init :: proc() -> (mesh: Mesh) {
	mesh.vertices = make([dynamic]MeshVertex)
	mesh.indices = make([dynamic]types.Vec3u)
	mesh.textures = make([dynamic]Texture)
	return
}

mesh_send_to_gpu :: proc(mesh: ^Mesh) {
	gl.GenVertexArrays(1, &mesh.vao)
	gl.GenBuffers(1, &mesh.vbo)
	gl.GenBuffers(1, &mesh.ebo)

	gl.BindVertexArray(mesh.vao)
	defer gl.BindVertexArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(mesh.vertices) * size_of(MeshVertex), raw_data(mesh.vertices), gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(mesh.indices) * size_of(types.Vec3u),
		raw_data(mesh.indices),
		gl.STATIC_DRAW,
	)

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(MeshVertex), offset_of(MeshVertex, position))

	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(MeshVertex), offset_of(MeshVertex, texture_coordinates))

	gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, size_of(MeshVertex), offset_of(MeshVertex, normal))
}

mesh_send_transforms_to_gpu :: proc(mesh: ^Mesh, transforms: []types.TransformMatrix) {
	gl.BindVertexArray(mesh.vao)
	defer gl.BindVertexArray(0)

	gl.GenBuffers(1, &mesh.transform_vbo)

	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.transform_vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(transforms) * size_of(types.TransformMatrix),
		raw_data(transforms),
		gl.STATIC_DRAW,
	)

	for i in 0 ..< 4 {
		index := u32(i) + 3
		gl.EnableVertexAttribArray(index)

		gl.VertexAttribPointer(
			index,
			4,
			gl.FLOAT,
			gl.FALSE,
			size_of(types.TransformMatrix),
			uintptr(i * size_of(types.Vec4)),
		)

		gl.VertexAttribDivisor(index, 1)
	}
}

mesh_set_material :: proc(mesh: ^Mesh, shader_id: u32) {
	mesh_set_textures(mesh, shader_id)
	shaders.set_float(shader_id, "material.shininess", mesh.material.shininess)
}

mesh_set_textures :: proc(mesh: ^Mesh, shader_id: u32) {
	diffuse_count, specular_count, normal_count, emissive_count: u32
	metallic_count, roughness_count, ao_count, displacement_count: u32
	albedo_count, alpha_count: u32

	for texture, i in mesh.textures {
		i := i32(i)
		gl.ActiveTexture(gl.TEXTURE0 + u32(i))
		texture_type: string
		number: u32 = ---

		switch texture.type {
		case .Diffuse:
			texture_type = "diffuse"
			number = diffuse_count
			diffuse_count += 1
		case .Specular:
			texture_type = "specular"
			number = specular_count
			specular_count += 1
		case .Normal:
			texture_type = "normal"
			number = normal_count
			normal_count += 1
		case .Emissive:
			texture_type = "emissive"
			number = emissive_count
			emissive_count += 1
		case .Albedo:
			texture_type = "alpha"
			number = albedo_count
			albedo_count += 1
		case .Metallic:
			texture_type = "metallic"
			number = metallic_count
			metallic_count += 1
		case .Roughness:
			texture_type = "roughness"
			number = roughness_count
			roughness_count += 1
		case .Displacement:
			texture_type = "displacement"
			number = displacement_count
			displacement_count += 1
		case .AO:
			texture_type = "ao"
			number = ao_count
			ao_count += 1
		case .Alpha:
			texture_type = "alpha"
			number = alpha_count
			alpha_count += 1
		}

		texture_name := fmt.caprintf("material.{}_{}", texture_type, number)
		defer delete(texture_name)

		shaders.set_int(shader_id, texture_name, i)
		gl.BindTexture(gl.TEXTURE_2D, texture.id)
	}

	gl.ActiveTexture(gl.TEXTURE0)
}

mesh_draw :: proc(mesh: ^Mesh, shader_id: u32) {
	gl.BindVertexArray(mesh.vao)
	defer gl.BindVertexArray(0)

	gl.DrawElements(gl.TRIANGLES, i32(len(mesh.indices)) * 3, gl.UNSIGNED_INT, nil)
}

mesh_draw_instanced :: proc(mesh: ^Mesh, shader_id: u32, num_instances: i32) {
	gl.BindVertexArray(mesh.vao)
	defer gl.BindVertexArray(0)

	gl.DrawElementsInstanced(gl.TRIANGLES, i32(len(mesh.indices)) * 3, gl.UNSIGNED_INT, nil, num_instances)
}


mesh_gpu_free :: proc(mesh: ^Mesh) {
	gl.DeleteVertexArrays(1, &mesh.vao)
	gl.DeleteBuffers(1, &mesh.vbo)
	gl.DeleteBuffers(1, &mesh.ebo)

	if mesh.transform_vbo != 0 do gl.DeleteBuffers(1, &mesh.transform_vbo)
}

mesh_free :: proc(mesh: ^Mesh) {
	delete(mesh.vertices)
	delete(mesh.indices)
	delete(mesh.material_name)
	delete(mesh.textures)
}
