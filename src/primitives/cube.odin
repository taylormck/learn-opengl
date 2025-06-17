package primitives

import "../render"
import "../types"
import "../utils"
import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"

@(private = "file")
VERTICES :: [?]render.Vertex {
	// Back face
	{position = {-0.5, -0.5, -0.5}, texture_coords = {0.0, 0.0}, normal = {0, 0, -1}},
	{position = {0.5, 0.5, -0.5}, texture_coords = {1.0, 1.0}, normal = {0, 0, -1}},
	{position = {0.5, -0.5, -0.5}, texture_coords = {1.0, 0.0}, normal = {0, 0, -1}},
	{position = {0.5, 0.5, -0.5}, texture_coords = {1.0, 1.0}, normal = {0, 0, -1}},
	{position = {-0.5, -0.5, -0.5}, texture_coords = {0.0, 0.0}, normal = {0, 0, -1}},
	{position = {-0.5, 0.5, -0.5}, texture_coords = {0.0, 1.0}, normal = {0, 0, -1}},
	// Front face
	{position = {-0.5, -0.5, 0.5}, texture_coords = {0.0, 0.0}, normal = {0, 0, 1}},
	{position = {0.5, -0.5, 0.5}, texture_coords = {1.0, 0.0}, normal = {0, 0, 1}},
	{position = {0.5, 0.5, 0.5}, texture_coords = {1.0, 1.0}, normal = {0, 0, 1}},
	{position = {0.5, 0.5, 0.5}, texture_coords = {1.0, 1.0}, normal = {0, 0, 1}},
	{position = {-0.5, 0.5, 0.5}, texture_coords = {0.0, 1.0}, normal = {0, 0, 1}},
	{position = {-0.5, -0.5, 0.5}, texture_coords = {0.0, 0.0}, normal = {0, 0, 1}},
	// Left face
	{position = {-0.5, 0.5, 0.5}, texture_coords = {1.0, 0.0}, normal = {-1, 0, 0}},
	{position = {-0.5, 0.5, -0.5}, texture_coords = {1.0, 1.0}, normal = {-1, 0, 0}},
	{position = {-0.5, -0.5, -0.5}, texture_coords = {0.0, 1.0}, normal = {-1, 0, 0}},
	{position = {-0.5, -0.5, -0.5}, texture_coords = {0.0, 1.0}, normal = {-1, 0, 0}},
	{position = {-0.5, -0.5, 0.5}, texture_coords = {0.0, 0.0}, normal = {-1, 0, 0}},
	{position = {-0.5, 0.5, 0.5}, texture_coords = {1.0, 0.0}, normal = {-1, 0, 0}},
	// Right face
	{position = {0.5, 0.5, 0.5}, texture_coords = {1.0, 0.0}, normal = {1, 0, 0}},
	{position = {0.5, -0.5, -0.5}, texture_coords = {0.0, 1.0}, normal = {1, 0, 0}},
	{position = {0.5, 0.5, -0.5}, texture_coords = {1.0, 1.0}, normal = {1, 0, 0}},
	{position = {0.5, -0.5, -0.5}, texture_coords = {0.0, 1.0}, normal = {1, 0, 0}},
	{position = {0.5, 0.5, 0.5}, texture_coords = {1.0, 0.0}, normal = {1, 0, 0}},
	{position = {0.5, -0.5, 0.5}, texture_coords = {0.0, 0.0}, normal = {1, 0, 0}},
	// Bottom face
	{position = {-0.5, -0.5, -0.5}, texture_coords = {0.0, 1.0}, normal = {0, -1, 0}},
	{position = {0.5, -0.5, -0.5}, texture_coords = {1.0, 1.0}, normal = {0, -1, 0}},
	{position = {0.5, -0.5, 0.5}, texture_coords = {1.0, 0.0}, normal = {0, -1, 0}},
	{position = {0.5, -0.5, 0.5}, texture_coords = {1.0, 0.0}, normal = {0, -1, 0}},
	{position = {-0.5, -0.5, 0.5}, texture_coords = {0.0, 0.0}, normal = {0, -1, 0}},
	{position = {-0.5, -0.5, -0.5}, texture_coords = {0.0, 1.0}, normal = {0, -1, 0}},
	// Top face
	{position = {-0.5, 0.5, -0.5}, texture_coords = {0.0, 1.0}, normal = {0, 1, 0}},
	{position = {0.5, 0.5, 0.5}, texture_coords = {1.0, 0.0}, normal = {0, 1, 0}},
	{position = {0.5, 0.5, -0.5}, texture_coords = {1.0, 1.0}, normal = {0, 1, 0}},
	{position = {0.5, 0.5, 0.5}, texture_coords = {1.0, 0.0}, normal = {0, 1, 0}},
	{position = {-0.5, 0.5, -0.5}, texture_coords = {0.0, 1.0}, normal = {0, 1, 0}},
	{position = {-0.5, 0.5, 0.5}, texture_coords = {0.0, 0.0}, normal = {0, 1, 0}},
}

@(private = "file")
vao, vbo: u32

cube_send_to_gpu :: proc(location := #caller_location) {
	ensure(vao == 0, "attempted to send cube to GPU twice.")
	ensure(vbo == 0, "attempted to send cube to GPU twice.")
	log.info("Sending cube data to the GPU", location = location)

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)

	gl.BindVertexArray(vao)
	vertex_data := VERTICES

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(render.Vertex) * len(vertex_data), &vertex_data, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, position))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, texture_coords))
	gl.EnableVertexAttribArray(1)

	gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, normal))
	gl.EnableVertexAttribArray(2)
}

cube_clear_from_gpu :: proc(location := #caller_location) {
	ensure(vao != 0, "attempted to remove cube from GPU but was already clear.")
	ensure(vbo != 0, "attempted to remove cube from GPU but was already clear.")
	log.info("Clearing cube data from the GPU", location = location)

	gl.DeleteBuffers(1, &vbo)
	gl.DeleteVertexArrays(1, &vao)
}

cube_draw :: proc() {
	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.DrawArrays(gl.TRIANGLES, 0, 36)
}
