package primitives

import "../render"
import "../types"
import gl "vendor:OpenGL"

NUM_PLANE_VERTICES :: 4

PLANE_VERTICES := [NUM_PLANE_VERTICES]render.Vertex {
	// near right
	{position = {25, -0.5, 25}, texture_coords = {25, 0}, color = {0, 1, 1}, normal = {0, 1, 0}},
	// near left
	{position = {-25, -0.5, 25}, texture_coords = {0, 0}, color = {1, 0, 0}, normal = {0, 1, 0}},
	// far right
	{position = {25, -0.5, -25}, texture_coords = {25, 25}, color = {0, 1, 0}, normal = {0, 1, 0}},
	// far left
	{position = {-25, -0.5, -25}, texture_coords = {0, 25}, color = {0, 0, 1}, normal = {0, 1, 0}},
}

PLANE_INDICES := [2]types.Vec3u{{0, 1, 2}, {1, 3, 2}}

plane_vao, plane_vbo, plane_ebo: u32

plane_send_to_gpu :: proc() {
	assert(plane_vao == 0, "Plane VAO already set")
	assert(plane_vbo == 0, "Plane VBO already set")
	assert(plane_ebo == 0, "Plane EBO already set")

	gl.GenVertexArrays(1, &plane_vao)
	gl.GenBuffers(1, &plane_vbo)
	gl.GenBuffers(1, &plane_ebo)

	gl.BindVertexArray(plane_vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, plane_vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(render.Vertex) * NUM_PLANE_VERTICES,
		raw_data(PLANE_VERTICES[:]),
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

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, plane_ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(PLANE_INDICES), &PLANE_INDICES, gl.STATIC_DRAW)
}

plane_clear_from_gpu :: proc() {
	assert(plane_vao != 0, "Plane VAO not set")
	assert(plane_vbo != 0, "Plane VBO not set")
	assert(plane_ebo != 0, "Plane EBO not set")

	gl.DeleteBuffers(1, &plane_vbo)
	gl.DeleteBuffers(1, &plane_ebo)
	gl.DeleteVertexArrays(1, &plane_vao)
}

plane_draw :: proc() {
	assert(plane_vao != 0, "Plane VAO not set")
	assert(plane_vbo != 0, "Plane VBO not set")
	assert(plane_ebo != 0, "Plane EBO not set")

	gl.BindVertexArray(plane_vao)
	defer gl.BindVertexArray(0)

	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
}
