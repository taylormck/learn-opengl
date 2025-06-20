package primitives

import "../render"
import "../types"
import "core:log"
import gl "vendor:OpenGL"

@(private = "file")
NUM_VERTICES :: 4

@(private = "file")
VERTICES :: [NUM_VERTICES]render.Vertex {
	// near right
	{position = {25, -0.5, 25}, texture_coords = {25, 0}, color = {0, 1, 1}, normal = {0, 1, 0}},
	// near left
	{position = {-25, -0.5, 25}, texture_coords = {0, 0}, color = {1, 0, 0}, normal = {0, 1, 0}},
	// far right
	{position = {25, -0.5, -25}, texture_coords = {25, 25}, color = {0, 1, 0}, normal = {0, 1, 0}},
	// far left
	{position = {-25, -0.5, -25}, texture_coords = {0, 25}, color = {0, 0, 1}, normal = {0, 1, 0}},
}

@(private = "file")
INDICES := [2]types.Vec3u{{0, 1, 2}, {1, 3, 2}}

@(private = "file")
vao, vbo, ebo: u32

plane_send_to_gpu :: proc(location := #caller_location) {
	ensure(vao == 0, "Attempted to send fullscreen data to GPU twice.")
	ensure(vbo == 0, "Attempted to send fullscreen data to GPU twice.")
	ensure(ebo == 0, "Attempted to send fullscreen data to GPU twice.")
	log.info("Sending plane data to the GPU", location = location)

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	vertices := VERTICES
	render.send_vertices_to_gpu(vertices[:])

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(INDICES), &INDICES, gl.STATIC_DRAW)
}

plane_clear_from_gpu :: proc(location := #caller_location) {
	ensure(vbo != 0, "Attempted to clear fullscreen data from GPU, but was already clear.")
	log.info("Clearing plane data from the GPU", location = location)

	gl.DeleteBuffers(1, &vbo)
	vbo = 0

	gl.DeleteBuffers(1, &ebo)
	ebo = 0

	gl.DeleteVertexArrays(1, &vao)
	vao = 0
}

plane_draw :: proc() {
	ensure(vao != 0, "Attempted to draw plane, but plane data has not been sent to the GPU.")

	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
}
