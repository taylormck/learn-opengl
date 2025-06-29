package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "font"
import "input"
import "primitives"
import "shaders"
import "tableau"
import "types"
import "utils"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "window"

INITIAL_WIDTH :: 800
INITIAL_HEIGHT :: 600

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3
NUM_SAMPLES :: 4

FONT_PATH :: "../fonts/Crimson_Text/CrimsonText-Regular.ttf"
TITLE_FONT_SCALE :: 65
HELP_FONT_SCALE :: 45
title_font: font.Font
help_font: font.Font
TITLE_START_POSITION :: types.Vec2{-0.95, 0.85}
TITLE_COLOR :: types.Vec3{1, 1, 1}
HELP_START_POSITION :: types.Vec2{-0.95, -0.85}
HELP_COLOR :: types.Vec3{1, 1, 1}

tableau_list := tableau.tableaus
current_tableau_index := len(tableau_list) - 1

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(.Debug)
	} else {
		context.logger = log.create_console_logger(.Info)
	}
	defer log.destroy_console_logger(context.logger)

	log.info("Initializing GLFW context")
	ensure(bool(glfw.Init()), "GLFW failed to init.")
	defer glfw.Terminate()

	log.infof("Setting OpenGL version: {}.{} - Core Profile", GL_MAJOR_VERSION, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	when ODIN_OS == .Darwin {
		log.info("Dawrin detected. Setting forward compatibility.")
		glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)
	}

	log.infof("Setting number of samples per pixel: {}", NUM_SAMPLES)
	glfw.WindowHint(glfw.SAMPLES, NUM_SAMPLES)

	log.infof("Creating window: width: {}, height: {}", INITIAL_WIDTH, INITIAL_HEIGHT)
	window_handle := glfw.CreateWindow(INITIAL_WIDTH, INITIAL_HEIGHT, "Renderer", nil, nil)
	defer glfw.DestroyWindow(window_handle)

	ensure(window_handle != nil, "GLFW failed to open the window.")

	glfw.MakeContextCurrent(window_handle)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	gl.Viewport(0, 0, INITIAL_WIDTH, INITIAL_HEIGHT)
	glfw.SetFramebufferSizeCallback(window_handle, framebuffer_size_callback)

	num_extensions: i32
	gl.GetIntegerv(gl.NUM_EXTENSIONS, &num_extensions)
	extensions: map[cstring]bool

	for i in 0 ..< num_extensions {
		ext := gl.GetStringi(gl.EXTENSIONS, u32(i))
		extensions[ext] = true
	}

	log.infof("GL_ARB_shader_viewport_layer_array is supported : {}", "GL_ARB_shader_viewport_layer_array" in extensions)
	utils.print_gl_errors()

	glfw.SetInputMode(window_handle, glfw.CURSOR, glfw.CURSOR_DISABLED)
	glfw.SetCursorPosCallback(window_handle, mouse_callback)
	glfw.SetScrollCallback(window_handle, scroll_callback)
	glfw.SetKeyCallback(window_handle, key_callback)

	window.width = INITIAL_WIDTH
	window.height = INITIAL_HEIGHT
	window.samples = NUM_SAMPLES

	init_input()

	gl.Enable(gl.MULTISAMPLE)

	current_tableau := &tableau_list[current_tableau_index]
	if init := current_tableau.init; init != nil {
		log.infof("Initializing tableau: {}", current_tableau.title)
		init()
	}

	// We need the quad to render text for all of the scenes, so let's just load it up now.
	primitives.quad_send_to_gpu()
	defer primitives.quad_clear_from_gpu()

	font_data := #load(FONT_PATH)
	title_font = font.font_init("CrimsonText", font_data, TITLE_FONT_SCALE)
	defer font.font_deinit(&title_font)

	help_font = font.font_init("CrimsonText", font_data, HELP_FONT_SCALE)
	defer font.font_deinit(&help_font)

	utils.print_gl_errors()

	defer shaders.delete_shaders()

	prev_time := glfw.GetTime()
	tableau_changed_prev_frame := false

	log.info("Entering main loop")
	for !glfw.WindowShouldClose(window_handle) {
		new_time := glfw.GetTime()
		delta := new_time - prev_time

		glfw.PollEvents()
		process_input(window_handle, delta)

		if tableau_changed_prev_frame {
			clear_input()
			tableau_changed_prev_frame = false
		} else {
			tableau_changed: bool
			current_tableau, tableau_changed = update_tableau(window_handle)
			tableau_changed_prev_frame = tableau_changed
		}

		if update := current_tableau.update; update != nil do update(delta)

		clear_input()

		current_tableau.draw()
		utils.print_gl_errors()

		if title := current_tableau.title; len(title) > 0 {
			font.font_write(&title_font, title, TITLE_START_POSITION, TITLE_COLOR)
		}

		if help_text := current_tableau.help_text; len(help_text) > 0 {
			font.font_write(&help_font, help_text, HELP_START_POSITION, HELP_COLOR)
		}

		glfw.SwapBuffers(window_handle)
		prev_time = new_time
		free_all(context.temp_allocator)
	}

	log.info("Exiting main loop")

	if teardown := current_tableau.teardown; teardown != nil {
		log.info("Tearing down tableau")
		teardown()
	}
}

framebuffer_size_callback :: proc "cdecl" (window_handle: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()
	window.width = width
	window.height = height

	gl.Viewport(0, 0, width, height)

	if callback := tableau_list[current_tableau_index].framebuffer_size_callback; callback != nil do callback()
}

update_tableau :: proc(window_handle: glfw.WindowHandle) -> (current_tableau: ^types.Tableau, updated: bool) {
	tableau_offset := 0
	if .LeftArrow in input.input_state.pressed_keys do tableau_offset -= 1
	if .RightArrow in input.input_state.pressed_keys do tableau_offset += 1

	if tableau_offset != 0 {
		updated = true

		if teardown := tableau_list[current_tableau_index].teardown; teardown != nil {
			log.info("Tearing down tableau")
			teardown()
		}

		current_tableau_index += len(tableau_list) + tableau_offset
		current_tableau_index %= len(tableau_list)

		current_tableau = &tableau_list[current_tableau_index]

		draw_tableau_change_filler(window_handle, current_tableau)

		if init := current_tableau.init; init != nil {
			log.infof("Initializing tableau: {}", current_tableau.title)
			init()
		}

		utils.print_gl_errors()
	} else {
		current_tableau = &tableau_list[current_tableau_index]
	}

	return current_tableau, updated
}

draw_tableau_change_filler :: proc(window_handle: glfw.WindowHandle, current_tableau: ^types.Tableau) {
	title := fmt.tprintf("Loading tableau: {}", current_tableau.title)
	help_text := "Please wait..."

	gl.ClearColor(0, 0, 0, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.Disable(gl.DEPTH_TEST)

	font.font_write(&title_font, title, TITLE_START_POSITION, TITLE_COLOR)
	font.font_write(&help_font, help_text, HELP_START_POSITION, HELP_COLOR)

	glfw.SwapBuffers(window_handle)
}
