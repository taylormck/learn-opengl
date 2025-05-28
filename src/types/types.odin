package types

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32
Vec3u :: [3]u32

TransformMatrix :: matrix[4, 4]f32
SubTransformMatrix :: matrix[3, 3]f32

VoidProc :: #type proc()
DeltaProc :: #type proc(delta: f64)

Tableau :: struct {
	init:                      VoidProc,
	update:                    DeltaProc,
	draw:                      VoidProc,
	teardown:                  VoidProc,
	framebuffer_size_callback: VoidProc,
}
