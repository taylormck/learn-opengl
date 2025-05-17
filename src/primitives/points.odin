package primitives

import "../render"
import "../types"
import gl "vendor:OpenGL"

NUM_POINTS :: 4

POINT_POSITIONS := [NUM_POINTS]types.Vec3 {
	{-0.5, 0.5, 0.0}, // top left
	{0.5, 0.5, 0.0}, // top right
	{0.5, -0.5, 0.0}, // bottom right
	{-0.5, -0.5, 0.0}, // bottom left
}

POINT_COLORS := [NUM_POINTS]types.Vec3 {
	{1, 0, 0}, // top left
	{0, 1, 0}, // top right
	{0, 0, 0}, // bottom right
	{1, 1, 0}, // bottom left
}

points_vao, points_vbo: u32

points_send_to_gpu :: proc() {
	gl.GenVertexArrays(1, &points_vao)
	gl.GenBuffers(1, &points_vbo)

	gl.BindVertexArray(points_vao)

	positions_offset := 0
	positions_size := size_of(types.Vec3) * len(POINT_POSITIONS)
	colors_offset := positions_offset + positions_size
	colors_size := size_of(types.Vec2) * len(POINT_COLORS)
	total_size := positions_size + colors_size

	gl.BindBuffer(gl.ARRAY_BUFFER, points_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, total_size, nil, gl.STATIC_DRAW)

	gl.BufferSubData(gl.ARRAY_BUFFER, positions_offset, positions_size, raw_data(POINT_POSITIONS[:]))
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
	gl.EnableVertexAttribArray(0)

	gl.BufferSubData(gl.ARRAY_BUFFER, colors_offset, colors_size, raw_data(POINT_COLORS[:]))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), uintptr(colors_offset))
	gl.EnableVertexAttribArray(1)
}

points_clear_from_gpu :: proc() {
	gl.DeleteBuffers(1, &points_vbo)
	gl.DeleteVertexArrays(1, &points_vao)
}

points_draw :: proc() {
	gl.BindVertexArray(points_vao)
	defer gl.BindVertexArray(0)

	gl.DrawArrays(gl.POINTS, 0, 4)
}
