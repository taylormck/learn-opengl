package primitives

import "../render"
import "../types"
import gl "vendor:OpenGL"

NUM_TRIANGLE_VERTICES :: 3

TRIANGLE_VERTEX_POSITIONS := [NUM_TRIANGLE_VERTICES]types.Vec3 {
	{-0.5, -0.5, 0}, // bottom left
	{0.5, -0.5, 0}, // bottom right
	{0, 0.5, 0}, // top
}

TRIANGLE_VERTEX_COLORS := [NUM_TRIANGLE_VERTICES]types.Vec3 {
	{1, 0, 0}, // bottom left
	{0, 1, 0}, // bottom right
	{0, 0, 1}, // top
}

TRIANGLE_TEXTURE_COORDS := [NUM_TRIANGLE_VERTICES]types.Vec2 {
	{0, 0}, // bottom left
	{1, 0}, // bottom right
	{0.5, 1}, // top
}

triangle_vertex_data_alloc :: proc() -> (vertex_data: render.VertexData) {
	append(&vertex_data.positions, ..TRIANGLE_VERTEX_POSITIONS[:])
	append(&vertex_data.colors, ..TRIANGLE_VERTEX_COLORS[:])
	append(&vertex_data.uvs, ..TRIANGLE_TEXTURE_COORDS[:])

	assert(len(vertex_data.positions) == len(vertex_data.colors))
	assert(len(vertex_data.positions) == len(vertex_data.uvs))

	return
}

triangle_send_to_gpu :: proc(vertex_data: render.VertexData, vao, vbo: u32) {
	gl.BindVertexArray(vao)

	positions_offset := 0
	positions_size := size_of(types.Vec3) * len(vertex_data.positions)
	colors_offset := positions_size
	colors_size := size_of(types.Vec3) * len(vertex_data.colors)
	uvs_offset := colors_offset + colors_size
	uvs_size := size_of(types.Vec2) * len(vertex_data.uvs)
	normals_offset := uvs_offset + uvs_size
	normals_size := size_of(types.Vec3) + normals_offset
	total_size := positions_size + colors_size + uvs_size + normals_size
	indices := RECTANGLE_INDICES

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, total_size, nil, gl.STATIC_DRAW)

	gl.BufferSubData(gl.ARRAY_BUFFER, 0, positions_size, raw_data(vertex_data.positions))
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
	gl.EnableVertexAttribArray(0)

	gl.BufferSubData(gl.ARRAY_BUFFER, colors_offset, colors_size, raw_data(vertex_data.colors))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), uintptr(colors_offset))
	gl.EnableVertexAttribArray(1)

	gl.BufferSubData(gl.ARRAY_BUFFER, uvs_offset, uvs_size, raw_data(vertex_data.uvs))
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(types.Vec2), uintptr(uvs_offset))
	gl.EnableVertexAttribArray(2)

	gl.BufferSubData(gl.ARRAY_BUFFER, normals_offset, normals_size, raw_data(vertex_data.normals))
	gl.VertexAttribPointer(3, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), uintptr(normals_offset))
	gl.EnableVertexAttribArray(3)
}

triangle_draw :: proc(vao: u32) {
	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.DrawArrays(gl.TRIANGLES, 0, 3)
}
