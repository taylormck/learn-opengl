package chapter_05_advanced_lighting

import "../../input"
import "../../parse/obj"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
initial_camera_position := types.Vec3{-5, -2, 4}

@(private = "file")
initial_camera_target := types.Vec3{0, -4, 0}

@(private = "file")
camera := render.Camera {
	type         = .Flying,
	position     = initial_camera_position,
	direction    = linalg.normalize(initial_camera_target - initial_camera_position),
	up           = {0, 1, 0},
	fov          = linalg.to_radians(f32(45)),
	aspect_ratio = window.aspect_ratio(),
	near         = 0.1,
	far          = 1000,
	speed        = 5,
}

@(private = "file")
backpack_model: render.Scene

@(private = "file")
backpack_transform :=
	linalg.matrix4_translate_f32({0, -4, 0}) *
	linalg.matrix4_rotate_f32(linalg.to_radians(f32(180)), {0, 1, 0}) *
	linalg.matrix4_rotate_f32(linalg.to_radians(f32(-90)), {1, 0, 0})

@(private = "file")
backpack_mit: types.SubTransformMatrix

@(private = "file")
cube_transform := linalg.matrix4_translate_f32({0, 2.5, 0}) * linalg.matrix4_scale_f32(15)

@(private = "file")
cube_mit: types.SubTransformMatrix

@(private = "file")
ambient := types.Vec3{0.5, 0.5, 0.5}

@(private = "file")
diffuse := types.Vec3{1.0, 1.0, 1.0}

@(private = "file")
light := render.PointLight {
	position  = types.Vec3{0, 0, 0},
	ambient   = {1, 1, 1},
	diffuse   = {1, 1, 1},
	specular  = {0, 0, 0},
	constant  = 1,
	linear    = 0.09,
	quadratic = 0.032,
}

@(private = "file")
g_buffer_fbo, rbo: u32

@(private = "file")
NUM_G_BUFFERS :: 3

@(private = "file")
g_buffers: [NUM_G_BUFFERS]u32

@(private = "file")
attachments: [NUM_G_BUFFERS]u32

@(private = "file")
draw_debug := true

@(private = "file")
debug_channel: i32 = 0

exercise_09_01_ssao := types.Tableau {
	init = proc() {
		shaders.init_shaders(.SSAO, .GBufferDebug)

		primitives.cube_send_to_gpu()
		primitives.full_screen_send_to_gpu()

		backpack_model =
			obj.load_scene_from_file_obj("models/backpack", "backpack.obj") or_else panic("Failed to load backpack model.")
		render.scene_send_to_gpu(&backpack_model)

		backpack_mit = types.SubTransformMatrix(linalg.inverse_transpose(backpack_transform))
		cube_mit = types.SubTransformMatrix(linalg.inverse_transpose(cube_transform))

		gl.GenFramebuffers(1, &g_buffer_fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, g_buffer_fbo)

		gl.GenTextures(NUM_G_BUFFERS, raw_data(g_buffers[:]))

		for i in 0 ..< NUM_G_BUFFERS {
			i := u32(i)
			gl.BindTexture(gl.TEXTURE_2D, g_buffers[i])
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, window.width, window.height, 0, gl.RGBA, gl.FLOAT, nil)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
			gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0 + i, gl.TEXTURE_2D, g_buffers[i], 0)

			attachments[i] = gl.COLOR_ATTACHMENT0 + i
		}
		gl.BindTexture(gl.TEXTURE_2D, 0)

		gl.DrawBuffers(NUM_G_BUFFERS, raw_data(attachments[:]))

		gl.GenRenderbuffers(1, &rbo)
		gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, window.width, window.height)
		gl.BindRenderbuffer(gl.RENDERBUFFER, 0)

		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, rbo)

		ensure(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE, "Framebuffer incomplete!")
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	},
	update = proc(delta: f64) {
		render.camera_move(&camera, input.input_state.movement, f32(delta))
		render.camera_update_direction(&camera, input.input_state.mouse.offset)
		camera.aspect_ratio = window.aspect_ratio()
		camera.fov = clamp(
			camera.fov - input.input_state.mouse.scroll_offset,
			linalg.to_radians(f32(1)),
			linalg.to_radians(f32(45)),
		)

		if .Space in input.input_state.pressed_keys do draw_debug = !draw_debug
		if .UpArrow in input.input_state.pressed_keys do debug_channel = (debug_channel + 1) % NUM_G_BUFFERS
		if .DownArrow in input.input_state.pressed_keys {
			debug_channel = (debug_channel + NUM_G_BUFFERS - 1) % NUM_G_BUFFERS
		}
	},
	draw = proc() {
		scene_shader := shaders.shaders[.SSAO]
		debug_shader := shaders.shaders[.GBufferDebug]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.Enable(gl.DEPTH_TEST)
		gl.Enable(gl.CULL_FACE)

		gl.BindFramebuffer(gl.FRAMEBUFFER, g_buffer_fbo)

		gl.ClearColor(0, 0, 0, 0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.UseProgram(scene_shader)

		// Render the backpack
		{
			transform := pv * backpack_transform

			shaders.set_mat_4x4(scene_shader, "transform", raw_data(&transform))
			shaders.set_mat_4x4(scene_shader, "model", raw_data(&backpack_transform))
			shaders.set_mat_3x3(scene_shader, "mit", raw_data(&backpack_mit))
			shaders.set_bool(scene_shader, "invert_normals", false)

			render.scene_draw(&backpack_model, scene_shader)
		}

		// Render outside cube
		{
			gl.CullFace(gl.FRONT)
			transform := pv * cube_transform

			shaders.set_mat_4x4(scene_shader, "transform", raw_data(&transform))
			shaders.set_mat_4x4(scene_shader, "model", raw_data(&cube_transform))
			shaders.set_mat_3x3(scene_shader, "mit", raw_data(&cube_mit))
			shaders.set_bool(scene_shader, "invert_normals", true)

			primitives.cube_draw()
			gl.CullFace(gl.BACK)
		}

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

		gl.Disable(gl.DEPTH_TEST)

		for i in 0 ..< NUM_G_BUFFERS {
			gl.ActiveTexture(gl.TEXTURE0 + u32(i))
			gl.BindTexture(gl.TEXTURE_2D, g_buffers[i])
		}

		if draw_debug {
			gl.UseProgram(debug_shader)
			gl.ClearColor(0, 0, 0, 0)
			gl.Clear(gl.COLOR_BUFFER_BIT)

			shaders.set_int(debug_shader, "g_position", 0)
			shaders.set_int(debug_shader, "g_normal", 1)
			shaders.set_int(debug_shader, "g_albedo_spec", 2)

			shaders.set_int(debug_shader, "channel", debug_channel)

			primitives.full_screen_draw()
			return
		}

		// TODO: draw the scene

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		primitives.full_screen_clear_from_gpu()
		render.scene_clear_from_gpu(&backpack_model)

		gl.DeleteTextures(NUM_G_BUFFERS, raw_data(g_buffers[:]))
		gl.DeleteRenderbuffers(1, &rbo)
	},
	framebuffer_size_callback = proc() {
		for i in 0 ..< NUM_G_BUFFERS {
			gl.BindTexture(gl.TEXTURE_2D, g_buffers[i])
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, window.width, window.height, 0, gl.RGBA, gl.FLOAT, nil)
		}
		gl.BindTexture(gl.TEXTURE_2D, 0)

		gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, window.width, window.height)
		gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
	},
}
