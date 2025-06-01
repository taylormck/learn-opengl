package primitives

import "../render"
import "../types"
import gl "vendor:OpenGL"

NUM_QUAD_VERTICES :: 4

QUAD_VERTICES := [NUM_QUAD_VERTICES]render.Vertex {
	// top right
	{
		position = {0.5, 0.5, 0.0},
		texture_coords = {1, 1},
		color = {0, 1, 1},
		normal = {0, 0, 1},
		tangent = {1, 0, 0},
		bitangent = {0, 1, 0},
	},
	// top left
	{
		position = {-0.5, 0.5, 0.0},
		texture_coords = {0, 1},
		color = {1, 0, 0},
		normal = {0, 0, 1},
		tangent = {1, 0, 0},
		bitangent = {0, 1, 0},
	},
	// bottom right
	{
		position = {0.5, -0.5, 0.0},
		texture_coords = {1, 0},
		color = {0, 1, 0},
		normal = {0, 0, 1},
		tangent = {1, 0, 0},
		bitangent = {0, 1, 0},
	},
	// bottom left
	{
		position = {-0.5, -0.5, 0.0},
		texture_coords = {0, 0},
		color = {0, 0, 1},
		normal = {0, 0, 1},
		tangent = {1, 0, 0},
		bitangent = {0, 1, 0},
	},
}

QUAD_INDICES := [2]types.Vec3u{{0, 1, 2}, {1, 3, 2}}

quad_vao, quad_vbo, quad_ebo: u32

quad_send_to_gpu :: proc() {
	t1, t2, b1, b2, e1, e2: types.Vec3

	gl.GenVertexArrays(1, &quad_vao)
	gl.GenBuffers(1, &quad_vbo)
	gl.GenBuffers(1, &quad_ebo)

	gl.BindVertexArray(quad_vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, quad_vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(render.Vertex) * NUM_QUAD_VERTICES,
		raw_data(QUAD_VERTICES[:]),
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

	gl.VertexAttribPointer(4, 3, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, tangent))
	gl.EnableVertexAttribArray(4)

	gl.VertexAttribPointer(3, 3, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, bitangent))
	gl.EnableVertexAttribArray(5)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, quad_ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(QUAD_INDICES), &QUAD_INDICES, gl.STATIC_DRAW)
}

quad_clear_from_gpu :: proc() {
	gl.DeleteBuffers(1, &quad_vbo)
	gl.DeleteBuffers(1, &quad_ebo)
	gl.DeleteVertexArrays(1, &quad_vao)
}

quad_draw :: proc() {
	gl.BindVertexArray(quad_vao)
	defer gl.BindVertexArray(0)

	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
}

quad_draw_instanced :: proc(num_instances: i32, instance_data_vbo: u32) {
	gl.BindVertexArray(quad_vao)
	defer gl.BindVertexArray(0)

	// TODO: factor this out into some kind of setup function
	gl.EnableVertexAttribArray(4)
	gl.BindBuffer(gl.ARRAY_BUFFER, instance_data_vbo)
	gl.VertexAttribPointer(4, 2, gl.FLOAT, gl.FALSE, size_of(types.Vec2), 0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.VertexAttribDivisor(4, 1)

	gl.DrawElementsInstanced(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil, num_instances)
}
