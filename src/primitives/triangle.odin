package primitives

import "../render"
import gl "vendor:OpenGL"

NUM_TRIANGLE_VERTICES :: 3

TRIANGLE_VERTICES := [NUM_TRIANGLE_VERTICES]render.Vertex {
	// bottom left
	{position = {-0.5, -0.5, 0}, color = {1, 0, 0}, normal = {0, 0, 1}, texture_coords = {0, 0}},

	// bottom right
	{position = {0.5, -0.5, 0}, color = {0, 1, 0}, normal = {0, 0, 1}, texture_coords = {1, 0}},

	// top
	{position = {0, 0.5, 0}, color = {0, 0, 1}, normal = {0, 0, 1}, texture_coords = {0.5, 1}},
}

triangle_vao, triangle_vbo: u32

triangle_send_to_gpu :: proc() {
	assert(triangle_vao == 0, "attempted to send triangle to GPU twice")
	assert(triangle_vbo == 0, "attempted to send triangle to GPU twice")

	gl.GenVertexArrays(1, &triangle_vao)
	gl.GenBuffers(1, &triangle_vbo)

	gl.BindVertexArray(triangle_vao)
	defer gl.BindVertexArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, triangle_vbo)
	defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(render.Vertex) * NUM_TRIANGLE_VERTICES,
		raw_data(TRIANGLE_VERTICES[:]),
		gl.STATIC_DRAW,
	)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, position))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, texture_coords))
	gl.EnableVertexAttribArray(1)

	gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, normal))
	gl.EnableVertexAttribArray(2)

	gl.VertexAttribPointer(3, 3, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, color))
	gl.EnableVertexAttribArray(3)
}

triangle_clear_from_gpu :: proc() {
	gl.DeleteBuffers(1, &triangle_vbo)
	gl.DeleteVertexArrays(1, &triangle_vao)
}

triangle_draw :: proc() {
	gl.BindVertexArray(triangle_vao)
	defer gl.BindVertexArray(0)

	gl.DrawArrays(gl.TRIANGLES, 0, 3)
}
