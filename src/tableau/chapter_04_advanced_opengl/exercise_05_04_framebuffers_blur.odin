package chapter_04_advanced_opengl

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{4.5, 0.6, -0.3}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{0, 0, 0}

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

@(private = "file")
container_texture, metal_texture: render.Texture

@(private = "file")
fbo, fb_texture, rbo: u32

exercise_05_04_framebuffers_blur :: types.Tableau {
	title = "Blur",
	init = proc() {
		shaders.init_shaders(.TransformTexture, .Blur)
		container_texture = render.prepare_texture("textures/container.png", .Diffuse, true)
		metal_texture = render.prepare_texture("textures/metal.png", .Diffuse, true)
		primitives.cube_send_to_gpu()
		primitives.full_screen_send_to_gpu()
		camera = get_initial_camera()

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
		texture_shader := shaders.shaders[.TransformTexture]
		blur_shader := shaders.shaders[.Blur]

		gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)

		gl.ActiveTexture(gl.TEXTURE0)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)

		gl.UseProgram(texture_shader)
		shaders.set_int(texture_shader, "diffuse_0", 0)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		// Draw cubes first
		{
			cube_positions := [?]types.Vec3{{-1, 0, -1}, {2, 0, 0}}
			for position in cube_positions {
				gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
				model := linalg.matrix4_translate(position)
				transform := pv * model

				shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

				primitives.cube_draw()
			}
		}

		{
			// Draw floor
			gl.BindTexture(gl.TEXTURE_2D, metal_texture.id)
			model := linalg.matrix4_translate(types.Vec3{0, -0.5, 0})
			model = model * linalg.matrix4_rotate(linalg.to_radians(f32(-90)), types.Vec3{1, 0, 0})
			model = linalg.matrix4_scale_f32(types.Vec3{10, 1, 10}) * model
			transform := pv * model

			shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

			primitives.quad_draw()
		}

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.ClearColor(1, 1, 1, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.Disable(gl.DEPTH_TEST)
		gl.BindTexture(gl.TEXTURE_2D, fb_texture)

		gl.UseProgram(blur_shader)
		primitives.full_screen_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		primitives.full_screen_clear_from_gpu()
		gl.DeleteTextures(1, &container_texture.id)
		gl.DeleteTextures(1, &metal_texture.id)

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
	},
}
