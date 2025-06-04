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
		mouse = {position = {INITIAL_WIDTH / 2, INITIAL_HEIGHT / 2}},
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

}

clear_input :: proc() {
	input.input_state.mouse.offset = {}
	input.input_state.mouse.scroll_offset = 0
	input.input_state.pressed_keys = {}
}

key_callback :: proc "cdecl" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_B && action == glfw.PRESS do input.input_state.pressed_keys += {.B}
	if key == glfw.KEY_V && action == glfw.PRESS do input.input_state.pressed_keys += {.V}
	if key == glfw.KEY_SPACE && action == glfw.PRESS do input.input_state.pressed_keys += {.Space}
	if key == glfw.KEY_UP && action == glfw.PRESS do input.input_state.pressed_keys += {.UpArrow}
	if key == glfw.KEY_DOWN && action == glfw.PRESS do input.input_state.pressed_keys += {.DownArrow}
}

@(private = "file")
first_mouse := true

mouse_callback :: proc "cdecl" (window: glfw.WindowHandle, x, y: f64) {
	context = runtime.default_context()
	x := f32(x)
	y := f32(y)

	if first_mouse {
		input.input_state.mouse.position = {x, y}
		first_mouse = false
	}

	offset :=
		types.Vec2{x - input.input_state.mouse.position.x, input.input_state.mouse.position.y - y} * MOUSE_SENSITIVITY
	input.input_state.mouse.offset += offset

	input.input_state.mouse.position = {x, y}
}

scroll_callback :: proc "cdecl" (window: glfw.WindowHandle, x, y: f64) {
	context = runtime.default_context()
	SCROLL_SCALE :: 0.03
	y := f32(y * SCROLL_SCALE)
	input.input_state.mouse.scroll_offset += y
}
