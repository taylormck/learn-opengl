package primitives

import "../render"
import "../types"
import "core:log"
import gl "vendor:OpenGL"

NUM_FULL_SCREEN_VERTICES :: 3

FullScreenVertex :: struct {
	position:       types.Vec3,
	texture_coords: types.Vec2,
}

FULL_SCREEN_VERTICES := [NUM_FULL_SCREEN_VERTICES]FullScreenVertex {
	{position = {-1, -1, 0}, texture_coords = {0, 0}}, // bottom left
	{position = {3, -1, 0}, texture_coords = {2, 0}}, // bottom right
	{position = {-1, 3, 0}, texture_coords = {0, 2}}, // top left
}

full_screen_vao, full_screen_vbo: u32

full_screen_send_to_gpu :: proc(location := #caller_location) {
	log.info("Sending full screen triangle data to the GPU", location = location)
	gl.GenVertexArrays(1, &full_screen_vao)
	gl.GenBuffers(1, &full_screen_vbo)

	gl.BindVertexArray(full_screen_vao)
	defer gl.BindVertexArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, full_screen_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(FULL_SCREEN_VERTICES), raw_data(FULL_SCREEN_VERTICES[:]), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(FullScreenVertex), offset_of(FullScreenVertex, position))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(
		1,
		2,
		gl.FLOAT,
		gl.FALSE,
		size_of(FullScreenVertex),
		offset_of(FullScreenVertex, texture_coords),
	)
	gl.EnableVertexAttribArray(1)
}

full_screen_clear_from_gpu :: proc(location := #caller_location) {
	log.info("Clearing full screen triangle data from the GPU", location = location)
	gl.DeleteBuffers(1, &full_screen_vbo)
	gl.DeleteVertexArrays(1, &full_screen_vao)
}

full_screen_draw :: proc() {
	gl.BindVertexArray(full_screen_vao)
	defer gl.BindVertexArray(0)

	gl.DrawArrays(gl.TRIANGLES, 0, 3)
}
