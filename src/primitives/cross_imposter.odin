package primitives

import "../render"
import "../types"
import "core:log"
import gl "vendor:OpenGL"

@(private = "file")
VERTICES :: 8

@(private = "file")
POSITIONS := [VERTICES]types.Vec3 {
	{-0.5, 0.5, 0.5},
	{-0.5, -0.5, 0.5},
	{0.5, 0.5, -0.5},
	{0.5, -0.5, -0.5},
	{-0.5, 0.5, -0.5},
	{-0.5, -0.5, -0.5},
	{0.5, 0.5, 0.5},
	{0.5, -0.5, 0.5},
}

@(private = "file")
TEXTURE_COORDS := [VERTICES]types.Vec2{{0, 1}, {0, 0}, {1, 1}, {1, 0}, {0, 1}, {0, 0}, {1, 1}, {1, 0}}

@(private = "file")
INDICES := [?]types.Vec3u{{0, 1, 2}, {1, 3, 2}, {4, 5, 6}, {5, 7, 6}}

@(private = "file")
vao, vbo, ebo: u32

cross_imposter_send_to_gpu :: proc(location := #caller_location) {
	ensure(vao == 0, "attempted to send cross imposter to GPU twice.")
	ensure(vbo == 0, "attempted to send cross imposter to GPU twice.")
	ensure(ebo == 0, "attempted to send cross imposter to GPU twice.")
	log.info("Sending cross imposter data to the GPU", location = location)

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	gl.BindVertexArray(vao)

	positions_offset := 0
	positions_size := size_of(types.Vec3) * len(POSITIONS)
	uvs_offset := positions_offset + positions_size
	uvs_size := size_of(types.Vec2) * len(TEXTURE_COORDS)
	total_size := positions_size + uvs_size
	indices := INDICES

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, total_size, nil, gl.STATIC_DRAW)

	gl.BufferSubData(gl.ARRAY_BUFFER, 0, positions_size, raw_data(POSITIONS[:]))
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
	gl.EnableVertexAttribArray(0)

	gl.BufferSubData(gl.ARRAY_BUFFER, uvs_offset, uvs_size, raw_data(TEXTURE_COORDS[:]))
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(types.Vec2), uintptr(uvs_offset))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)
}

cross_imposter_clear_from_gpu :: proc(location := #caller_location) {
	ensure(vao != 0, "attempted to remove cross imposter from GPU but it was already removed.")
	ensure(vbo != 0, "attempted to remove cross imposter from GPU but it was already removed.")
	ensure(ebo != 0, "attempted to remove cross imposter from GPU but it was already removed.")
	log.info("Clearing cross imposter data from the GPU", location = location)
	gl.DeleteBuffers(1, &vbo)
	gl.DeleteBuffers(1, &ebo)
	gl.DeleteVertexArrays(1, &vao)
}

cross_imposter_draw :: proc() {
	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.DrawElements(gl.TRIANGLES, 12, gl.UNSIGNED_INT, nil)
}
