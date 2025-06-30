package primitives

import "../types"
import "core:log"
import gl "vendor:OpenGL"

@(private = "file")
NUM_POINTS :: 4

@(private = "file")
POSITIONS :: [NUM_POINTS]types.Vec3 {
	{-0.5, 0.5, 0.0}, // top left
	{0.5, 0.5, 0.0}, // top right
	{0.5, -0.5, 0.0}, // bottom right
	{-0.5, -0.5, 0.0}, // bottom left
}

@(private = "file")
COLORS :: [NUM_POINTS]types.Vec3 {
	{1, 0, 0}, // top left
	{0, 1, 0}, // top right
	{0, 0, 1}, // bottom right
	{1, 1, 0}, // bottom left
}

@(private = "file")
vao, vbo: u32

points_send_to_gpu :: proc(location := #caller_location) {
	ensure(vao == 0, "attempted to send points to GPU twice.")
	ensure(vbo == 0, "attempted to send points to GPU twice.")
	log.info("Sending points data to the GPU", location = location)

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)

	gl.BindVertexArray(vao)

	positions := POSITIONS
	colors := COLORS

	positions_offset := 0
	positions_size := size_of(positions)
	colors_offset := positions_offset + positions_size
	colors_size := size_of(colors)
	total_size := positions_size + colors_size

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, total_size, nil, gl.STATIC_DRAW)

	gl.BufferSubData(gl.ARRAY_BUFFER, positions_offset, positions_size, raw_data(positions[:]))
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
	gl.EnableVertexAttribArray(0)

	gl.BufferSubData(gl.ARRAY_BUFFER, colors_offset, colors_size, raw_data(colors[:]))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), uintptr(colors_offset))
	gl.EnableVertexAttribArray(1)
}

points_clear_from_gpu :: proc(location := #caller_location) {
	ensure(vao != 0, "attempted to clear points fromt GPU, but was already clear.")
	ensure(vbo != 0, "attempted to clear points fromt GPU, but was already clear.")
	log.info("Clearing points data from the GPU", location = location)

	gl.DeleteBuffers(1, &vbo)
	vbo = 0

	gl.DeleteVertexArrays(1, &vao)
	vao = 0
}

points_draw :: proc() {
	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.DrawArrays(gl.POINTS, 0, 4)
}
