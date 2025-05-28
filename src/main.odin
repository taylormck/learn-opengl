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

INITIAL_WIDTH :: 800
INITIAL_HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5
NUM_SAMPLES :: 4

ms_fbo, ms_fb_texture, ms_rbo: u32

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

	window.width = INITIAL_WIDTH
	window.height = INITIAL_HEIGHT

	init_input()

	// gl.GenFramebuffers(1, &ms_fbo)
	// defer gl.DeleteFramebuffers(1, &ms_fbo)
	// gl.BindFramebuffer(gl.FRAMEBUFFER, ms_fbo)
	//
	// gl.GenTextures(1, &ms_fb_texture)
	// gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, ms_fb_texture)
	// gl.TexImage2DMultisample(gl.TEXTURE_2D_MULTISAMPLE, NUM_SAMPLES, gl.RGB, INITIAL_WIDTH, INITIAL_HEIGHT, gl.TRUE)
	// gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, 0)
	//
	// gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D_MULTISAMPLE, ms_fb_texture, 0)
	//
	// gl.GenRenderbuffers(1, &ms_rbo)
	// gl.BindRenderbuffer(gl.RENDERBUFFER, ms_rbo)
	// gl.RenderbufferStorageMultisample(gl.RENDERBUFFER, NUM_SAMPLES, gl.DEPTH24_STENCIL8, INITIAL_WIDTH, INITIAL_HEIGHT)
	// gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
	//
	// gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, ms_rbo)
	//
	// if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE do panic("Multisample Framebuffer incomplete!")
	// gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	gl.Enable(gl.MULTISAMPLE)

	current_tableau := tableaus[.Chapter_04_11_01_anti_aliasing_msaa]

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

// draw_green_box :: proc() {
// 	gl.BindFramebuffer(gl.FRAMEBUFFER, ms_fbo)
//
// 	gl.ClearColor(0.1, 0.2, 0.3, 1)
// 	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
// 	gl.Enable(gl.DEPTH_TEST)
//
// 	model := linalg.matrix4_rotate_f32(math.PI / 4, types.Vec3{1, 1, 1})
// 	projection := render.camera_get_projection(&camera)
// 	view := render.camera_get_view(&camera)
// 	transform := projection * view * model
//
// 	gl.UseProgram(tableau.shaders[.SingleColor])
// 	gl.UniformMatrix4fv(
// 		gl.GetUniformLocation(tableau.shaders[.SingleColor], "transform"),
// 		1,
// 		false,
// 		raw_data(&transform),
// 	)
// 	primitives.cube_draw()
//
// 	gl.BindFramebuffer(gl.READ_FRAMEBUFFER, ms_fbo)
// 	gl.BindFramebuffer(gl.DRAW_FRAMEBUFFER, fbo)
// 	gl.BlitFramebuffer(
// 		0,
// 		0,
// 		window_width,
// 		window_height,
// 		0,
// 		0,
// 		window_width,
// 		window_height,
// 		gl.COLOR_BUFFER_BIT,
// 		gl.NEAREST,
// 	)
//
// 	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
// 	gl.ClearColor(0.1, 0.2, 0.3, 1)
// 	gl.Clear(gl.COLOR_BUFFER_BIT)
// 	gl.Disable(gl.DEPTH_TEST)
// 	gl.BindTexture(gl.TEXTURE_2D, fb_texture)
//
// 	gl.UseProgram(tableau.shaders[.Invert])
// 	primitives.full_screen_draw()
// }

framebuffer_size_callback :: proc "cdecl" (window_handle: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()
	window.width = width
	window.height = height

	gl.Viewport(0, 0, width, height)

	// gl.BindTexture(gl.TEXTURE_2D, fb_texture)
	// defer gl.BindTexture(gl.TEXTURE_2D, 0)
	// gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, nil)
	//
	// gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
	// defer gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
	// gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, width, height)
	//
	// gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, ms_fb_texture)
	// defer gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, 0)
	// gl.TexImage2DMultisample(gl.TEXTURE_2D_MULTISAMPLE, NUM_SAMPLES, gl.RGB, width, height, gl.TRUE)
	//
	// gl.BindRenderbuffer(gl.RENDERBUFFER, ms_rbo)
	// defer gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
	// gl.RenderbufferStorageMultisample(gl.RENDERBUFFER, NUM_SAMPLES, gl.DEPTH24_STENCIL8, width, height)
}
