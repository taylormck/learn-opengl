package primitives

import "../render"
import "../types"
import "../utils"
import "core:log"
import gl "vendor:OpenGL"

@(private = "file")
NUM_FULL_SCREEN_VERTICES :: 3

@(private = "file")
Vertex :: struct {
	position:       types.Vec3,
	texture_coords: types.Vec2,
}

@(private = "file")
VERTICES := [NUM_FULL_SCREEN_VERTICES]Vertex {
	{position = {-1, -1, 0}, texture_coords = {0, 0}}, // bottom left
	{position = {3, -1, 0}, texture_coords = {2, 0}}, // bottom right
	{position = {-1, 3, 0}, texture_coords = {0, 2}}, // top left
}

@(private = "file")
vao, vbo: u32

full_screen_send_to_gpu :: proc(location := #caller_location) {
	ensure(vao == 0, "Attempted to send fullscreen data to GPU twice.")
	ensure(vbo == 0, "Attempted to send fullscreen data to GPU twice.")
	log.info("Sending full screen triangle data to the GPU", location = location)

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)

	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	gl.BufferData(gl.ARRAY_BUFFER, size_of(VERTICES), raw_data(VERTICES[:]), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, position))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, texture_coords))
	gl.EnableVertexAttribArray(1)

	utils.print_gl_errors()
}

full_screen_clear_from_gpu :: proc(location := #caller_location) {
	ensure(vao != 0, "Attempted to clear fullscreen data from GPU, but was already clear.")
	ensure(vbo != 0, "Attempted to clear fullscreen data from GPU, but was already clear.")
	log.info("Clearing full screen triangle data from the GPU", location = location)

	gl.DeleteBuffers(1, &vbo)
	vbo = 0

	gl.DeleteVertexArrays(1, &vao)
	vao = 0
}

full_screen_draw :: proc() {
	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.DrawArrays(gl.TRIANGLES, 0, 3)
}

full_screen_draw_instanced :: proc(num_instances: i32) {
	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.DrawArraysInstanced(gl.TRIANGLES, 0, 3, num_instances)
}
