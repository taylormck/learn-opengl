package render

import "../types"

Vertex :: struct {
	position:       types.Vec3,
	color:          types.Vec3,
	texture_coords: types.Vec2,
	normal:         types.Vec3,
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
