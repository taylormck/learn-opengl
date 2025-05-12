package main

import "base:runtime"
import "core:math/linalg"
import "render"
import "types"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

MOUSE_SENSITIVITY :: 0.01

MouseStatus :: struct {
	position: types.Vec2,
}

mouse_info := MouseStatus {
	position = {WIDTH / 2, HEIGHT / 2},
}

process_input :: proc(window: glfw.WindowHandle, delta: f32) {
	CAMERA_SPEED :: 5

	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}

	camera_movement: types.Vec3

	if (glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS) do camera_movement += FORWARD
	if (glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS) do camera_movement += BACKWARD
	if (glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS) do camera_movement += LEFT
	if (glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS) do camera_movement += RIGHT

	// NOTE: input should probably be stashed in a global somewhere,
	// then this can run in the update directly.
	render.camera_move(&camera, camera_movement, delta)
}

@(private = "file")
first_mouse := true

mouse_callback :: proc "cdecl" (window: glfw.WindowHandle, x, y: f64) {
	context = runtime.default_context()
	x := f32(x)
	y := f32(y)

	if first_mouse {
		mouse_info.position = {x, y}
		first_mouse = false
	}

	offset := types.Vec2{x - mouse_info.position.x, mouse_info.position.y - y} * MOUSE_SENSITIVITY
	mouse_info.position = {x, y}

	render.camera_update_direction(&camera, offset)
}

scroll_callback :: proc "cdecl" (window: glfw.WindowHandle, x, y: f64) {
	context = runtime.default_context()
	SCROLL_SCALE :: 0.03
	y := f32(y) * SCROLL_SCALE

	camera.fov = clamp(camera.fov - y, linalg.to_radians(f32(1)), linalg.to_radians(f32(45)))
}
