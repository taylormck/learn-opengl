package chapter_05_advanced_lighting

import "../../input"
import "../../parse/obj"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math/linalg"
import "core:math/rand"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{7, 2, 7}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{0, -0.5, 0}

@(private = "file")
get_initial_camera :: proc() -> render.Camera {
	return {
		type = .Flying,
		position = INITIAL_CAMERA_POSITION,
		direction = linalg.normalize(INITIAL_CAMERA_TARGET - INITIAL_CAMERA_POSITION),
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
NUM_POINT_LIGHTS :: 32

@(private = "file")
point_lights: [NUM_POINT_LIGHTS]render.PointLight

@(private = "file")
point_light_transform := linalg.matrix4_translate_f32({-4, -1, -4}) * linalg.matrix4_scale_f32({8, 2, 8})

@(private = "file")
backpack_model: render.Scene

@(private = "file")
backpack_transforms := [?]types.TransformMatrix {
	linalg.matrix4_translate_f32({-3, -0.5, -3}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({0, -0.5, -3}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({3, -0.5, -3}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({-3, -0.5, 0}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({0, -0.5, 0}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({3, -0.5, 0}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({-3, -0.5, 3}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({0, -0.5, 3}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({3, -0.5, 3}) * linalg.matrix4_scale_f32(0.5),
}

@(private = "file")
backpack_mits: [len(backpack_transforms)]types.SubTransformMatrix

@(private = "file")
NUM_G_BUFFERS :: 3

@(private = "file")
g_buffers: [NUM_G_BUFFERS]u32

@(private = "file")
attachments: [NUM_G_BUFFERS]u32

@(private = "file")
gbuffer_fbo, rbo: u32

@(private = "file")
draw_debug := false

@(private = "file")
debug_channel: i32 = 0

@(private = "file")
NUM_DEBUG_CHANNELS :: 5

exercise_08_01_deferred_shading :: types.Tableau {
	title = "Deferred shading",
	help_text = "Press [SPACE] to toggle debug view. Press [UP]/[DOWN] to select the desired G Buffer.",
	init = proc() {
		shaders.init_shaders(.Light, .GBuffer, .GBufferDebug, .DeferredShading)

		camera = get_initial_camera()
		draw_debug = false
		debug_channel = 0

		backpack_model =
			obj.load_scene_from_file_obj("models/backpack", "backpack.obj") or_else panic("Failed to load backpack model.")
		render.scene_send_to_gpu(&backpack_model)

		primitives.cube_send_to_gpu()
		primitives.full_screen_send_to_gpu()

		for transform, i in backpack_transforms {
			backpack_mits[i] = types.SubTransformMatrix(linalg.inverse_transpose(transform))
		}

		for &light in point_lights {
			light = generate_random_point_light()
		}

		gl.GenFramebuffers(1, &gbuffer_fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, gbuffer_fbo)

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
		render.camera_common_update(&camera, delta)

		if .Space in input.input_state.pressed_keys do draw_debug = !draw_debug
		if .UpArrow in input.input_state.pressed_keys do debug_channel = (debug_channel + 1) % NUM_DEBUG_CHANNELS
		if .DownArrow in input.input_state.pressed_keys do debug_channel = (debug_channel + NUM_DEBUG_CHANNELS - 1) % NUM_DEBUG_CHANNELS
	},
	draw = proc() {
		light_shader := shaders.shaders[.Light]
		mesh_shader := shaders.shaders[.GBuffer]
		debug_shader := shaders.shaders[.GBufferDebug]
		lighting_shader := shaders.shaders[.DeferredShading]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		// Render the scene into the G-buffer
		gl.BindFramebuffer(gl.FRAMEBUFFER, gbuffer_fbo)
		gl.ClearColor(0, 0, 0, 0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		gl.UseProgram(mesh_shader)

		for &model, i in backpack_transforms {
			transform := pv * model
			mit := backpack_mits[i]

			shaders.set_mat_4x4(mesh_shader, "transform", raw_data(&transform))
			shaders.set_mat_4x4(mesh_shader, "model", raw_data(&model))
			shaders.set_mat_3x3(mesh_shader, "mit", raw_data(&mit))

			render.scene_draw_with_materials(&backpack_model, mesh_shader)
		}

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.ClearColor(background_color.r, background_color.g, background_color.b, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Disable(gl.DEPTH_TEST)

		for i in 0 ..< NUM_G_BUFFERS {
			gl.ActiveTexture(gl.TEXTURE0 + u32(i))
			gl.BindTexture(gl.TEXTURE_2D, g_buffers[i])
		}

		if draw_debug {
			gl.UseProgram(debug_shader)

			shaders.set_int(debug_shader, "g_position", 0)
			shaders.set_int(debug_shader, "g_normal", 1)
			shaders.set_int(debug_shader, "g_albedo_spec", 2)

			shaders.set_int(debug_shader, "channel", debug_channel)

			primitives.full_screen_draw()
			return
		}

		// Do the lighting pass
		gl.UseProgram(lighting_shader)
		shaders.set_int(lighting_shader, "num_point_lights", NUM_POINT_LIGHTS)
		for &point_light, i in point_lights {
			render.point_light_array_set_uniform(&point_light, lighting_shader, u32(i))
		}

		shaders.set_int(lighting_shader, "g_position", 0)
		shaders.set_int(lighting_shader, "g_normal", 1)
		shaders.set_int(lighting_shader, "g_albedo_spec", 2)

		shaders.set_vec3(lighting_shader, "view_position", raw_data(&camera.position))

		primitives.full_screen_draw()

		// Update the depth buffer
		gl.BindFramebuffer(gl.READ_FRAMEBUFFER, gbuffer_fbo)
		gl.BindFramebuffer(gl.DRAW_FRAMEBUFFER, 0)
		gl.BlitFramebuffer(
			0,
			0,
			window.width,
			window.height,
			0,
			0,
			window.width,
			window.height,
			gl.DEPTH_BUFFER_BIT,
			gl.NEAREST,
		)
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.Enable(gl.DEPTH_TEST)

		// Draw the lights
		gl.UseProgram(light_shader)
		for &point_light in point_lights {
			model := linalg.matrix4_translate(point_light.position)
			model *= linalg.matrix4_scale_f32({0.2, 0.2, 0.2})
			transform := pv * model

			shaders.set_mat_4x4(light_shader, "transform", raw_data(&transform))
			shaders.set_vec3(light_shader, "light_color", raw_data(&point_light.emissive))

			primitives.cube_draw()
		}
	},
	teardown = proc() {
		primitives.full_screen_clear_from_gpu()
		primitives.cube_clear_from_gpu()
		render.scene_clear_from_gpu(&backpack_model)
		render.scene_destroy(&backpack_model)

		gl.DeleteTextures(NUM_G_BUFFERS, raw_data(g_buffers[:]))
		gl.DeleteRenderbuffers(1, &rbo)
		gl.DeleteFramebuffers(1, &gbuffer_fbo)
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

@(private = "file")
generate_random_point_light :: proc() -> render.PointLight {
	position := point_light_transform * types.Vec4{rand.float32(), rand.float32(), rand.float32(), 1.0}
	color := types.Vec3{rand.float32(), rand.float32(), rand.float32()} * 0.5 + 0.5

	return render.PointLight {
		position = position.xyz,
		ambient = color * 0.1,
		diffuse = color,
		emissive = color,
		specular = color,
		constant = 1,
		linear = 0.8,
		quadratic = 0.4,
	}
}
