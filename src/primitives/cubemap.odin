package primitives

import "../render"
import "../types"
import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

NUM_SIDES :: 6

CUBEMAP_VERTICES := [?]types.Vec3 {
	// right
	{-1, 1, -1},
	{-1, -1, -1},
	{1, -1, -1},
	{1, -1, -1},
	{1, 1, -1},
	{-1, 1, -1},
	// left
	{-1, -1, 1},
	{-1, -1, -1},
	{-1, 1, -1},
	{-1, 1, -1},
	{-1, 1, 1},
	{-1, -1, 1},
	// top
	{1, -1, -1},
	{1, -1, 1},
	{1, 1, 1},
	{1, 1, 1},
	{1, 1, -1},
	{1, -1, -1},
	// bottom
	{-1, -1, 1},
	{-1, 1, 1},
	{1, 1, 1},
	{1, 1, 1},
	{1, -1, 1},
	{-1, -1, 1},
	// front
	{-1, 1, -1},
	{1, 1, -1},
	{1, 1, 1},
	{1, 1, 1},
	{-1, 1, 1},
	{-1, 1, -1},
	// back
	{-1, -1, -1},
	{-1, -1, 1},
	{1, -1, -1},
	{1, -1, -1},
	{-1, -1, 1},
	{1, -1, 1},
}

// NOTE: the names - and jpg extension - are currently hard-coded
FACE_NAMES: [NUM_SIDES]string = {"right.jpg", "left.jpg", "top.jpg", "bottom.jpg", "front.jpg", "back.jpg"}

Cubemap :: struct {
	vao, vbo, texture_id: u32,
}

cubemap_send_to_gpu :: proc(cubemap: ^Cubemap, location := #caller_location) {
	log.info("Sending cubemap data to the GPU", location = location)
	gl.GenVertexArrays(1, &cubemap.vao)
	gl.GenBuffers(1, &cubemap.vbo)

	gl.BindVertexArray(cubemap.vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, cubemap.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(types.Vec3) * len(CUBEMAP_VERTICES), &CUBEMAP_VERTICES, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
	gl.EnableVertexAttribArray(0)
}

cubemap_load :: proc(cubemap: ^Cubemap, path: string, flip_vertically: bool = false, location := #caller_location) {
	log.infof("Loading cubemap from file: {}", path, location = location)
	stbi.set_flip_vertically_on_load(1 if flip_vertically else 0)

	gl.GenTextures(1, &cubemap.texture_id)
	gl.BindTexture(gl.TEXTURE_CUBE_MAP, cubemap.texture_id)
	defer gl.BindTexture(gl.TEXTURE_CUBE_MAP, 0)

	for i in 0 ..< NUM_SIDES {
		image_path := fmt.caprintf("{}/{}", path, FACE_NAMES[i])
		img := render.load_texture_2d(image_path) or_else panic("Failed to load cubemap!")
		defer stbi.image_free(img.buffer)

		gl.TexImage2D(
			gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i),
			0,
			gl.RGB,
			img.width,
			img.height,
			0,
			gl.RGB,
			gl.UNSIGNED_BYTE,
			img.buffer,
		)
	}

	gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)
}

cubemap_destroy_texture :: proc(cubemap: ^Cubemap, location := #caller_location) {
	log.infof("Clearing cubemap texture data from the GPU: {}", cubemap.texture_id, location = location)
	gl.DeleteTextures(1, &cubemap.texture_id)
}

cubemap_clear_from_gpu :: proc(cubemap: ^Cubemap, location := #caller_location) {
	log.infof("Clearing cubemap data from the GPU: vao: {}, vbo: {}", cubemap.vao, cubemap.vbo, location = location)
	gl.DeleteBuffers(1, &cubemap.vbo)
	gl.DeleteVertexArrays(1, &cubemap.vao)
}

cubemap_draw :: proc(cubemap: ^Cubemap) {
	gl.BindVertexArray(cubemap.vao)

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_CUBE_MAP, cubemap.texture_id)
	defer gl.BindTexture(gl.TEXTURE_CUBE_MAP, 0)

	gl.DrawArrays(gl.TRIANGLES, 0, 36)
}
