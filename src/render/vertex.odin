package render

import "../types"
import "../utils"
import gl "vendor:OpenGL"

Vertex :: struct {
	position:       types.Vec3,
	color:          types.Vec3,
	texture_coords: types.Vec2,
	normal:         types.Vec3,
	tangent:        types.Vec3,
	bitangent:      types.Vec3,
}

VertexData :: struct {
	positions: [dynamic]types.Vec3,
	colors:    [dynamic]types.Vec3,
	uvs:       [dynamic]types.Vec2,
	normals:   [dynamic]types.Vec3,
}

vertex_data_free :: proc(v: ^VertexData) {
	delete(v.positions)
	delete(v.colors)
	delete(v.uvs)
	delete(v.normals)
}

send_vertices_to_gpu :: proc(vertices: []Vertex, location := #caller_location) {
	assert(utils.get_current_vao() != 0, "Attempted to send vertices to GPU, but VAO not bound")
	assert(utils.get_current_vbo() != 0, "Attempted to send vertices to GPU, but VBO not bound")
	ensure(len(vertices) > 0, "Attepmted to send vertices to GPU, but vertices slice was empty")

	gl.BufferData(gl.ARRAY_BUFFER, size_of(Vertex) * len(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, position))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, texture_coords))
	gl.EnableVertexAttribArray(1)

	gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, normal))
	gl.EnableVertexAttribArray(2)

	gl.VertexAttribPointer(3, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, color))
	gl.EnableVertexAttribArray(3)

	gl.VertexAttribPointer(4, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, tangent))
	gl.EnableVertexAttribArray(4)

	gl.VertexAttribPointer(5, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, bitangent))
	gl.EnableVertexAttribArray(5)

	utils.print_gl_errors(location = location)
}
