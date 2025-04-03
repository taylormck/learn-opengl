package render

import "../types"

VertexData :: struct {
    positions: [dynamic]types.Vec3,
    colors:    [dynamic]types.Vec3,
    uvs:       [dynamic]types.Vec2,
    normals:   [dynamic]types.Vec3,
}
