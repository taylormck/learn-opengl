package render

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec3u :: [3]u32

VertexData :: struct {
    positions: [dynamic]Vec3,
    colors:    [dynamic]Vec3,
    uvs:       [dynamic]Vec2,
    normals:   [dynamic]Vec3,
}
