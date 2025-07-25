package chapter_04_advanced_opengl

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec4{0.1, 0.1, 0.1, 1}

@(private = "file", rodata)
cube_color := types.Vec3{0, 1, 0}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{1.5, 1, 1.5}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{0, 0, 0}

@(private = "file")
ms_fbo, ms_fb_texture, ms_rbo: u32

@(private = "file")
fbo, fb_texture, rbo: u32

@(private = "file")
get_initial_camera :: proc() -> render.Camera {
	return {
		type = .Flying,
		position = INITIAL_CAMERA_POSITION,
		direction = INITIAL_CAMERA_TARGET - INITIAL_CAMERA_POSITION,
		up = {0, 1, 0},
		fov = linalg.to_radians(f32(45)),
		aspect_ratio = window.aspect_ratio(),
		near = 0.1,
		far = 1000,
		speed = 5,
	}
}

@(private = "file")
camera: render.Camera

exercise_11_02_anti_aliasing_offscreen :: types.Tableau {
	title = "Off-screen MSAA",
	init = proc() {
		shaders.init_shaders(.TransformUniformColor, .Invert)
		primitives.cube_send_to_gpu()
		primitives.full_screen_send_to_gpu()
		camera = get_initial_camera()

		gl.GenFramebuffers(1, &ms_fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, ms_fbo)

		gl.GenTextures(1, &ms_fb_texture)
		gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, ms_fb_texture)
		gl.TexImage2DMultisample(gl.TEXTURE_2D_MULTISAMPLE, window.samples, gl.RGB, window.width, window.height, gl.TRUE)
		gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, 0)

		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D_MULTISAMPLE, ms_fb_texture, 0)

		gl.GenRenderbuffers(1, &ms_rbo)
		gl.BindRenderbuffer(gl.RENDERBUFFER, ms_rbo)
		gl.RenderbufferStorageMultisample(
			gl.RENDERBUFFER,
			window.samples,
			gl.DEPTH24_STENCIL8,
			window.width,
			window.height,
		)
		gl.BindRenderbuffer(gl.RENDERBUFFER, 0)

		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, ms_rbo)

		ensure(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE, "Multisample Framebuffer incomplete!")

		gl.GenFramebuffers(1, &fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)

		gl.GenTextures(1, &fb_texture)
		gl.BindTexture(gl.TEXTURE_2D, fb_texture)

		// TODO: this needs to be updated on framebuffer resize callback
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, window.width, window.height, 0, gl.RGB, gl.UNSIGNED_BYTE, nil)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.BindTexture(gl.TEXTURE_2D, 0)

		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fb_texture, 0)

		gl.GenRenderbuffers(1, &rbo)
		gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, window.width, window.height)
		gl.BindRenderbuffer(gl.RENDERBUFFER, 0)

		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, rbo)

		ensure(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE, "Framebuffer incomplete!")
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
	},
	draw = proc() {
		single_color_shader := shaders.shaders[.TransformUniformColor]
		invert_shader := shaders.shaders[.Invert]

		gl.BindFramebuffer(gl.FRAMEBUFFER, ms_fbo)
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		transform := projection * view

		gl.UseProgram(single_color_shader)
		shaders.set_mat_4x4(single_color_shader, "transform", raw_data(&transform))
		shaders.set_vec4(single_color_shader, "our_color", raw_data(&cube_color))
		primitives.cube_draw()

		gl.BindFramebuffer(gl.READ_FRAMEBUFFER, ms_fbo)
		gl.BindFramebuffer(gl.DRAW_FRAMEBUFFER, fbo)
		gl.BlitFramebuffer(
			0,
			0,
			window.width,
			window.height,
			0,
			0,
			window.width,
			window.height,
			gl.COLOR_BUFFER_BIT,
			gl.NEAREST,
		)

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.Disable(gl.DEPTH_TEST)
		gl.BindTexture(gl.TEXTURE_2D, fb_texture)

		gl.UseProgram(invert_shader)
		primitives.full_screen_draw()
	},
	teardown = proc() {
		primitives.full_screen_clear_from_gpu()
		primitives.cube_clear_from_gpu()

		gl.DeleteTextures(1, &ms_fb_texture)
		gl.DeleteFramebuffers(1, &ms_fbo)
		gl.DeleteRenderbuffers(1, &ms_rbo)

		gl.DeleteTextures(1, &fb_texture)
		gl.DeleteFramebuffers(1, &fbo)
		gl.DeleteRenderbuffers(1, &rbo)
	},
	framebuffer_size_callback = proc() {
		gl.BindTexture(gl.TEXTURE_2D, fb_texture)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, window.width, window.height, 0, gl.RGB, gl.UNSIGNED_BYTE, nil)

		gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
		defer gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, window.width, window.height)

		gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, ms_fb_texture)
		defer gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, 0)
		gl.TexImage2DMultisample(gl.TEXTURE_2D_MULTISAMPLE, window.samples, gl.RGB, window.width, window.height, gl.TRUE)

		gl.BindRenderbuffer(gl.RENDERBUFFER, ms_rbo)
		defer gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
		gl.RenderbufferStorageMultisample(
			gl.RENDERBUFFER,
			window.samples,
			gl.DEPTH24_STENCIL8,
			window.width,
			window.height,
		)
	},
}
