package types
Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32
Vec3u :: [3]u32

TransformMatrix :: matrix[4, 4]f32
SubTransformMatrix :: matrix[3, 3]f32

Tableau :: struct {
	init:     #type proc(),
	draw:     #type proc(delta: f64),
	teardown: #type proc(),
}
