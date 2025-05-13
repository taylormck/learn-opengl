package mesh

import "../render"
import "../types"
import gl "vendor:OpenGL"

NUM_CROSS_IMPOSTER_VERTICES :: 8

CROSS_IMPOSTER_VERTEX_POSITIONS := [NUM_CROSS_IMPOSTER_VERTICES]types.Vec3 {
	{-0.5, 0.5, 0.5},
	{-0.5, -0.5, 0.5},
	{0.5, 0.5, -0.5},
	{0.5, -0.5, -0.5},
	{-0.5, 0.5, -0.5},
	{-0.5, -0.5, -0.5},
	{0.5, 0.5, 0.5},
	{0.5, -0.5, 0.5},
}

CROSS_IMPOSTER_TEXTURE_COORDS := [NUM_CROSS_IMPOSTER_VERTICES]types.Vec2 {
	{0, 1},
	{0, 0},
	{1, 1},
	{1, 0},
	{0, 1},
	{0, 0},
	{1, 1},
	{1, 0},
}

CROSS_IMPOSTER_INDICES := [?]types.Vec3u{{0, 1, 2}, {1, 3, 2}, {4, 5, 6}, {5, 7, 6}}

cross_imposter_vao, cross_imposter_vbo, cross_imposter_ebo: u32

cross_imposter_send_to_gpu :: proc() {
	gl.GenVertexArrays(1, &cross_imposter_vao)
	gl.GenBuffers(1, &cross_imposter_vbo)
	gl.GenBuffers(1, &cross_imposter_ebo)

	gl.BindVertexArray(cross_imposter_vao)

	positions_offset := 0
	positions_size := size_of(types.Vec3) * len(CROSS_IMPOSTER_VERTEX_POSITIONS)
	uvs_offset := positions_offset + positions_size
	uvs_size := size_of(types.Vec2) * len(CROSS_IMPOSTER_TEXTURE_COORDS)
	total_size := positions_size + uvs_size
	indices := CROSS_IMPOSTER_INDICES

	gl.BindBuffer(gl.ARRAY_BUFFER, cross_imposter_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, total_size, nil, gl.STATIC_DRAW)

	gl.BufferSubData(gl.ARRAY_BUFFER, 0, positions_size, raw_data(CROSS_IMPOSTER_VERTEX_POSITIONS[:]))
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
	gl.EnableVertexAttribArray(0)

	gl.BufferSubData(gl.ARRAY_BUFFER, uvs_offset, uvs_size, raw_data(CROSS_IMPOSTER_TEXTURE_COORDS[:]))
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(types.Vec2), uintptr(uvs_offset))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, cross_imposter_ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)
}

cross_imposter_clear_from_gpu :: proc() {
	gl.DeleteBuffers(1, &cross_imposter_vbo)
	gl.DeleteBuffers(1, &cross_imposter_ebo)
	gl.DeleteVertexArrays(1, &cross_imposter_vao)
}

cross_imposter_draw :: proc() {
	gl.BindVertexArray(cross_imposter_vao)
	defer gl.BindVertexArray(0)

	gl.DrawElements(gl.TRIANGLES, 12, gl.UNSIGNED_INT, nil)
}
