package main

import "base:runtime"
import "core:math/linalg"
import "input"
import "render"
import "types"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

MOUSE_SENSITIVITY :: 0.01

init_input :: proc() {
	input.input_state = input.InputState {
		mouse_position = {INITIAL_WIDTH / 2, INITIAL_HEIGHT / 2},
	}
}

process_input :: proc(window: glfw.WindowHandle, delta: f64) {
	CAMERA_SPEED :: 5

	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}

	input.input_state.movement = types.Vec3{}

	if (glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS) do input.input_state.movement += FORWARD
	if (glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS) do input.input_state.movement += BACKWARD
	if (glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS) do input.input_state.movement += LEFT
	if (glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS) do input.input_state.movement += RIGHT

	// NOTE: input should probably be stashed in a global somewhere,
	// then this can run in the update directly.
	// render.camera_move(&camera, input.input_state.movement, f32(delta))
}

@(private = "file")
first_mouse := true

mouse_callback :: proc "cdecl" (window: glfw.WindowHandle, x, y: f64) {
	context = runtime.default_context()
	x := f32(x)
	y := f32(y)

	if first_mouse {
		input.input_state.mouse_position = {x, y}
		first_mouse = false
	}

	offset :=
		types.Vec2{x - input.input_state.mouse_position.x, input.input_state.mouse_position.y - y} * MOUSE_SENSITIVITY
	input.input_state.mouse_position = {x, y}

	// render.camera_update_direction(&camera, offset)
}

scroll_callback :: proc "cdecl" (window: glfw.WindowHandle, x, y: f64) {
	context = runtime.default_context()
	SCROLL_SCALE :: 0.03
	y := f32(y) * SCROLL_SCALE

	// camera.fov = clamp(camera.fov - y, linalg.to_radians(f32(1)), linalg.to_radians(f32(45)))
}
