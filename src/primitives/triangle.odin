package primitives

import "../render"
import "core:log"
import gl "vendor:OpenGL"

@(private = "file")
NUM_TRIANGLE_VERTICES :: 3

@(private = "file")
VERTICES :: [NUM_TRIANGLE_VERTICES]render.Vertex {
	// bottom left
	{position = {-0.5, -0.5, 0}, color = {1, 0, 0}, normal = {0, 0, 1}, texture_coords = {0, 0}},

	// bottom right
	{position = {0.5, -0.5, 0}, color = {0, 1, 0}, normal = {0, 0, 1}, texture_coords = {1, 0}},

	// top
	{position = {0, 0.5, 0}, color = {0, 0, 1}, normal = {0, 0, 1}, texture_coords = {0.5, 1}},
}

@(private = "file")
vao, vbo: u32

triangle_send_to_gpu :: proc(location := #caller_location) {
	ensure(vao == 0, "attempted to send triangle to GPU twice")
	ensure(vbo == 0, "attempted to send triangle to GPU twice")
	log.info("Sending triangle data to the GPU", location = location)

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)

	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	vertices := VERTICES
	render.send_vertices_to_gpu(vertices[:])
}

triangle_clear_from_gpu :: proc(location := #caller_location) {
	ensure(vao != 0, "attempted to remove triangle from GPU but was already removed.")
	ensure(vbo != 0, "attempted to remove triangle from GPU but was already removed.")
	log.info("Clearing triangle data from the GPU", location = location)

	gl.DeleteBuffers(1, &vbo)
	vbo = 0

	gl.DeleteVertexArrays(1, &vao)
	vao = 0
}

triangle_draw :: proc() {
	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.DrawArrays(gl.TRIANGLES, 0, 3)
}
