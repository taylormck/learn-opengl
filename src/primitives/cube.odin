package primitives

import "../render"
import "../types"
import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"

NUM_CUBE_VERTICES :: 36

CubeVertex :: struct {
	position, normal: types.Vec3,
	uv:               types.Vec2,
}

CUBE_VERTICES :: [?]CubeVertex {
	// Back face
	{position = {-0.5, -0.5, -0.5}, uv = {0.0, 0.0}, normal = {0, 0, -1}},
	{position = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}, normal = {0, 0, -1}},
	{position = {0.5, -0.5, -0.5}, uv = {1.0, 0.0}, normal = {0, 0, -1}},
	{position = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}, normal = {0, 0, -1}},
	{position = {-0.5, -0.5, -0.5}, uv = {0.0, 0.0}, normal = {0, 0, -1}},
	{position = {-0.5, 0.5, -0.5}, uv = {0.0, 1.0}, normal = {0, 0, -1}},
	// Front face
	{position = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}, normal = {0, 0, 1}},
	{position = {0.5, -0.5, 0.5}, uv = {1.0, 0.0}, normal = {0, 0, 1}},
	{position = {0.5, 0.5, 0.5}, uv = {1.0, 1.0}, normal = {0, 0, 1}},
	{position = {0.5, 0.5, 0.5}, uv = {1.0, 1.0}, normal = {0, 0, 1}},
	{position = {-0.5, 0.5, 0.5}, uv = {0.0, 1.0}, normal = {0, 0, 1}},
	{position = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}, normal = {0, 0, 1}},
	// Left face
	{position = {-0.5, 0.5, 0.5}, uv = {1.0, 0.0}, normal = {-1, 0, 0}},
	{position = {-0.5, 0.5, -0.5}, uv = {1.0, 1.0}, normal = {-1, 0, 0}},
	{position = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}, normal = {-1, 0, 0}},
	{position = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}, normal = {-1, 0, 0}},
	{position = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}, normal = {-1, 0, 0}},
	{position = {-0.5, 0.5, 0.5}, uv = {1.0, 0.0}, normal = {-1, 0, 0}},
	// Right face
	{position = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}, normal = {1, 0, 0}},
	{position = {0.5, -0.5, -0.5}, uv = {0.0, 1.0}, normal = {1, 0, 0}},
	{position = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}, normal = {1, 0, 0}},
	{position = {0.5, -0.5, -0.5}, uv = {0.0, 1.0}, normal = {1, 0, 0}},
	{position = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}, normal = {1, 0, 0}},
	{position = {0.5, -0.5, 0.5}, uv = {0.0, 0.0}, normal = {1, 0, 0}},
	// Bottom face
	{position = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}, normal = {0, -1, 0}},
	{position = {0.5, -0.5, -0.5}, uv = {1.0, 1.0}, normal = {0, -1, 0}},
	{position = {0.5, -0.5, 0.5}, uv = {1.0, 0.0}, normal = {0, -1, 0}},
	{position = {0.5, -0.5, 0.5}, uv = {1.0, 0.0}, normal = {0, -1, 0}},
	{position = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}, normal = {0, -1, 0}},
	{position = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}, normal = {0, -1, 0}},
	// Top face
	{position = {-0.5, 0.5, -0.5}, uv = {0.0, 1.0}, normal = {0, 1, 0}},
	{position = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}, normal = {0, 1, 0}},
	{position = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}, normal = {0, 1, 0}},
	{position = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}, normal = {0, 1, 0}},
	{position = {-0.5, 0.5, -0.5}, uv = {0.0, 1.0}, normal = {0, 1, 0}},
	{position = {-0.5, 0.5, 0.5}, uv = {0.0, 0.0}, normal = {0, 1, 0}},
}

cube_vao, cube_vbo: u32

cube_send_to_gpu :: proc() {
	gl.GenVertexArrays(1, &cube_vao)
	gl.GenBuffers(1, &cube_vbo)

	gl.BindVertexArray(cube_vao)
	vertex_data := CUBE_VERTICES

	gl.BindBuffer(gl.ARRAY_BUFFER, cube_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(CubeVertex) * len(vertex_data), &vertex_data, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(CubeVertex), offset_of(CubeVertex, position))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(CubeVertex), offset_of(CubeVertex, uv))
	gl.EnableVertexAttribArray(1)

	gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, size_of(CubeVertex), offset_of(CubeVertex, normal))
	gl.EnableVertexAttribArray(2)
}

cube_clear_from_gpu :: proc() {
	gl.DeleteBuffers(1, &cube_vbo)
	gl.DeleteVertexArrays(1, &cube_vao)
}

cube_draw :: proc() {
	gl.BindVertexArray(cube_vao)
	defer gl.BindVertexArray(0)

	gl.DrawArrays(gl.TRIANGLES, 0, 36)
}
