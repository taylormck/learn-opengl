package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:os"
import "core:slice"
import "parse/obj"
import "primitives"
import "render"
import "shaders"
import "types"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "window"

import "tableau/chapter_01_getting_started"
import "tableau/chapter_02_lighting"
import "tableau/chapter_03_model_loading"
import "tableau/chapter_04_advanced_opengl"
import "tableau/chapter_05_advanced_lighting"

INITIAL_WIDTH :: 800
INITIAL_HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5
NUM_SAMPLES :: 4

current_tableau: types.Tableau

main :: proc() {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	if !bool(glfw.Init()) {
		panic("GLFW failed to init.")
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)
	glfw.WindowHint(glfw.SAMPLES, NUM_SAMPLES)

	window_handle := glfw.CreateWindow(INITIAL_WIDTH, INITIAL_HEIGHT, "Renderer", nil, nil)
	defer glfw.DestroyWindow(window_handle)

	if window_handle == nil {
		panic("GLFW failed to open the window.")
	}

	glfw.MakeContextCurrent(window_handle)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	gl.Viewport(0, 0, INITIAL_WIDTH, INITIAL_HEIGHT)
	glfw.SetFramebufferSizeCallback(window_handle, framebuffer_size_callback)

	glfw.SetInputMode(window_handle, glfw.CURSOR, glfw.CURSOR_DISABLED)
	glfw.SetCursorPosCallback(window_handle, mouse_callback)
	glfw.SetScrollCallback(window_handle, scroll_callback)
	glfw.SetKeyCallback(window_handle, key_callback)

	window.width = INITIAL_WIDTH
	window.height = INITIAL_HEIGHT
	window.samples = NUM_SAMPLES

	init_input()

	gl.Enable(gl.MULTISAMPLE)

	current_tableau = chapter_05_advanced_lighting.exercise_03_01_01_depth

	if current_tableau.init != nil do current_tableau.init()
	defer if current_tableau.teardown != nil do current_tableau.teardown()
	defer shaders.delete_shaders()

	prev_time := glfw.GetTime()

	for !glfw.WindowShouldClose(window_handle) {
		new_time := glfw.GetTime()
		delta := new_time - prev_time

		glfw.PollEvents()
		process_input(window_handle, delta)

		if current_tableau.update != nil do current_tableau.update(delta)

		clear_input()

		current_tableau.draw()

		glfw.SwapBuffers(window_handle)
		prev_time = new_time
	}
}

framebuffer_size_callback :: proc "cdecl" (window_handle: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()
	window.width = width
	window.height = height

	gl.Viewport(0, 0, width, height)

	if current_tableau.framebuffer_size_callback != nil do current_tableau.framebuffer_size_callback()
}
