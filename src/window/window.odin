package window

width: i32
height: i32
samples: i32

aspect_ratio :: proc() -> f32 {
	return f32(width) / f32(height)
}
