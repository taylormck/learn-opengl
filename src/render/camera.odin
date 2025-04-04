package render

import "../types"
import "core:math"
import "core:math/linalg"

CAMERA_SPEED :: 5

Camera :: struct {
    position, direction, up:      types.Vec3,
    fov, aspect_ratio, near, far: f32,
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
