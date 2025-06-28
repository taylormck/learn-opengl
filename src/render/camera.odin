package render

import "../input"
import "../types"
import "../window"
import "core:math"
import "core:math/linalg"

CameraType :: enum {
	Flying,
	FPS,
}

Camera :: struct {
	type:                                CameraType,
	position, direction, up:             types.Vec3,
	fov, aspect_ratio, near, far, speed: f32,
}

camera_update_direction :: proc "cdecl" (camera: ^Camera, offset: types.Vec2) {
	yaw := linalg.atan2(camera.direction.z, camera.direction.x)

	pitch_adjacent := math.sqrt(camera.direction.x * camera.direction.x + camera.direction.z * camera.direction.z)

	pitch := linalg.atan2(camera.direction.y, pitch_adjacent)

	yaw += offset.x
	pitch = clamp(pitch + offset.y, linalg.to_radians(f32(-89)), linalg.to_radians(f32(89)))

	camera.direction = linalg.normalize(
		types.Vec3{math.cos(yaw) * math.cos(pitch), math.sin(pitch), math.sin(yaw) * math.cos(pitch)},
	)
}

camera_get_view :: proc(camera: ^Camera) -> types.TransformMatrix {
	return linalg.matrix4_look_at_f32(camera.position, camera.position + camera.direction, camera.up)
}

camera_get_projection :: proc(camera: ^Camera) -> types.TransformMatrix {
	return linalg.matrix4_perspective_f32(
		fovy = camera.fov,
		aspect = camera.aspect_ratio,
		near = camera.near,
		far = camera.far,
	)
}

camera_move :: proc(camera: ^Camera, direction: types.Vec3, delta: f32) {
	movement: types.Vec3
	right := linalg.normalize(linalg.cross(camera.direction, camera.up))

	switch camera.type {
	case .Flying:
		movement += direction.z * camera.direction
		movement += direction.x * right
	case .FPS:
		forward := types.Vec3{camera.direction.x, 0, camera.direction.z}
		movement += direction.z * forward
		movement += direction.x * right
	}

	camera.position += movement * camera.speed * delta
}

camera_common_update :: proc(camera: ^Camera, delta: f64) {
	camera.aspect_ratio = window.aspect_ratio()

	camera_move(camera, input.input_state.movement, f32(delta))
	camera_update_direction(camera, input.input_state.mouse.offset)
	camera.fov = clamp(
		camera.fov - input.input_state.mouse.scroll_offset,
		linalg.to_radians(f32(1)),
		linalg.to_radians(f32(45)),
	)
}
