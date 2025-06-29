package chapter_05_advanced_lighting

import "../../input"
import "../../parse/obj"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../utils"
import "../../window"
import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{-5, -2, 4}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{0, -4, 0}

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
backpack_model: render.Scene

@(private = "file")
backpack_transform :=
	linalg.matrix4_translate_f32({0, -4, 0}) *
	linalg.matrix4_rotate_f32(linalg.to_radians(f32(180)), {0, 1, 0}) *
	linalg.matrix4_rotate_f32(linalg.to_radians(f32(-90)), {1, 0, 0})

@(private = "file")
cube_transform := linalg.matrix4_translate_f32({0, 2.5, 0}) * linalg.matrix4_scale_f32(15)

@(private = "file")
ambient := types.Vec3{0.5, 0.5, 0.5}

@(private = "file")
diffuse := types.Vec3{1.0, 1.0, 1.0}

@(private = "file")
light := render.PointLight {
	position  = {2, 4, -2},
	ambient   = {0.2, 0.2, 0.7},
	diffuse   = {0.2, 0.2, 0.7},
	specular  = {0, 0, 0},
	emissive  = {0, 0, 0},
	constant  = 1,
	linear    = 0.04,
	quadratic = 0.012,
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
draw_debug := false

@(private = "file")
debug_channel: i32 = 0

@(private = "file")
NUM_SAMPLES :: 64

@(private = "file")
sample_offsets: [NUM_SAMPLES]types.Vec3

@(private = "file")
sample_rotation_noise: [16]types.Vec3

@(private = "file")
noise_texture: u32

@(private = "file")
ssao_fbo, ssao_color_buffer, ssao_blur_fbo, ssao_blur_texture: u32

exercise_09_01_ssao :: types.Tableau {
	title = "SSAO",
	help_text = "Press [SPACE] to toggle debug view. Press [UP]/[DOWN] to select the desired G Buffer.",
	init = proc() {
		shaders.init_shaders(.SSAOGeometry, .GBufferDebug, .SSAOLighting, .SSAODepth, .SSAOBlur)

		camera = get_initial_camera()

		primitives.cube_send_to_gpu()
		primitives.full_screen_send_to_gpu()

		backpack_model =
			obj.load_scene_from_file_obj("models/backpack", "backpack.obj") or_else panic("Failed to load backpack model.")
		render.scene_send_to_gpu(&backpack_model)

		for i in 0 ..< NUM_SAMPLES do sample_offsets[i] = generate_sample_offset(i)
		for &noise_vector in sample_rotation_noise do noise_vector = generate_noise_vector()

		gl.GenFramebuffers(1, &g_buffer_fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, g_buffer_fbo)

		gl.GenTextures(NUM_G_BUFFERS, raw_data(g_buffers[:]))

		for i in 0 ..< NUM_G_BUFFERS {
			i := u32(i)
			gl.BindTexture(gl.TEXTURE_2D, g_buffers[i])
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, window.width, window.height, 0, gl.RGBA, gl.FLOAT, nil)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0 + i, gl.TEXTURE_2D, g_buffers[i], 0)

			attachments[i] = gl.COLOR_ATTACHMENT0 + i
		}

		gl.DrawBuffers(NUM_G_BUFFERS, raw_data(attachments[:]))

		gl.GenRenderbuffers(1, &rbo)
		gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, window.width, window.height)

		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, rbo)

		ensure(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE, "Framebuffer incomplete!")

		gl.GenFramebuffers(1, &ssao_fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, ssao_fbo)

		gl.GenTextures(1, &ssao_color_buffer)
		gl.BindTexture(gl.TEXTURE_2D, ssao_color_buffer)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, window.width, window.height, 0, gl.RED, gl.FLOAT, nil)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, ssao_color_buffer, 0)

		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, rbo)
		ensure(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE, "Framebuffer incomplete!")

		gl.GenFramebuffers(1, &ssao_blur_fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, ssao_blur_fbo)

		gl.GenTextures(1, &ssao_blur_texture)
		gl.BindTexture(gl.TEXTURE_2D, ssao_blur_texture)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, window.width, window.height, 0, gl.RED, gl.FLOAT, nil)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, ssao_blur_texture, 0)

		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, rbo)
		ensure(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE, "Framebuffer incomplete!")

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

		gl.GenTextures(1, &noise_texture)
		gl.BindTexture(gl.TEXTURE_2D, noise_texture)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, 4, 4, 0, gl.RGB, gl.FLOAT, raw_data(sample_rotation_noise[:]))
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

		gl.BindTexture(gl.TEXTURE_2D, 0)
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)

		if .Space in input.input_state.pressed_keys do draw_debug = !draw_debug
		if .UpArrow in input.input_state.pressed_keys do debug_channel = (debug_channel + 1) % NUM_G_BUFFERS
		if .DownArrow in input.input_state.pressed_keys {
			debug_channel = (debug_channel + NUM_G_BUFFERS - 1) % NUM_G_BUFFERS
		}
	},
	draw = proc() {
		geometry_pass_shader := shaders.shaders[.SSAOGeometry]
		debug_shader := shaders.shaders[.GBufferDebug]
		depth_shader := shaders.shaders[.SSAODepth]
		blur_shader := shaders.shaders[.SSAOBlur]
		lighting_shader := shaders.shaders[.SSAOLighting]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		gl.Enable(gl.CULL_FACE)
		defer gl.Disable(gl.CULL_FACE)

		gl.BindFramebuffer(gl.FRAMEBUFFER, g_buffer_fbo)

		gl.ClearColor(0, 0, 0, 0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.UseProgram(geometry_pass_shader)
		shaders.set_mat_4x4(geometry_pass_shader, "projection", raw_data(&projection))

		// Render the backpack
		{
			model_view := view * backpack_transform
			model_view_it := types.SubTransformMatrix(linalg.inverse_transpose(model_view))

			shaders.set_mat_4x4(geometry_pass_shader, "model_view", raw_data(&model_view))
			shaders.set_mat_3x3(geometry_pass_shader, "model_view_it", raw_data(&model_view_it))
			shaders.set_bool(geometry_pass_shader, "invert_normals", false)

			render.scene_draw(&backpack_model, geometry_pass_shader)
		}

		// Render outside cube
		{
			gl.CullFace(gl.FRONT)
			model_view := view * cube_transform
			model_view_it := types.SubTransformMatrix(linalg.inverse_transpose(model_view))

			shaders.set_mat_4x4(geometry_pass_shader, "model_view", raw_data(&model_view))
			shaders.set_mat_3x3(geometry_pass_shader, "model_view_it", raw_data(&model_view_it))
			shaders.set_bool(geometry_pass_shader, "invert_normals", true)

			primitives.cube_draw()
			gl.CullFace(gl.BACK)
		}

		gl.Disable(gl.DEPTH_TEST)

		for i in 0 ..< NUM_G_BUFFERS {
			gl.ActiveTexture(gl.TEXTURE0 + u32(i))
			gl.BindTexture(gl.TEXTURE_2D, g_buffers[i])
		}

		if draw_debug {
			gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
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

		// draw the depth
		gl.BindFramebuffer(gl.FRAMEBUFFER, ssao_fbo)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		for i in 0 ..< 2 {
			gl.ActiveTexture(gl.TEXTURE0 + u32(i))
			gl.BindTexture(gl.TEXTURE_2D, g_buffers[i])
		}

		gl.ActiveTexture(gl.TEXTURE2)
		gl.BindTexture(gl.TEXTURE_2D, noise_texture)

		gl.UseProgram(depth_shader)
		shaders.set_int(depth_shader, "g_position", 0)
		shaders.set_int(depth_shader, "g_normal", 1)
		shaders.set_int(depth_shader, "noise", 2)
		shaders.set_int(depth_shader, "kernel_size", NUM_SAMPLES)
		shaders.set_float(depth_shader, "radius", 0.5)
		shaders.set_float(depth_shader, "bias", 0.025)

		for &sample, i in sample_offsets {
			shaders.set_vec3(depth_shader, fmt.ctprintf("samples[{}]", i), raw_data(sample[:]))
		}

		shaders.set_mat_4x4(depth_shader, "projection", raw_data(&projection))
		shaders.set_float(depth_shader, "window_width", f32(window.width))
		shaders.set_float(depth_shader, "window_height", f32(window.height))

		primitives.full_screen_draw()

		// Blur the SSAO output
		gl.BindFramebuffer(gl.FRAMEBUFFER, ssao_blur_fbo)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, ssao_color_buffer)

		gl.UseProgram(blur_shader)
		shaders.set_int(blur_shader, "ssao_input", 0)

		primitives.full_screen_draw()

		// lighting pass
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		for i in 0 ..< NUM_G_BUFFERS {
			gl.ActiveTexture(gl.TEXTURE0 + u32(i))
			gl.BindTexture(gl.TEXTURE_2D, g_buffers[i])
		}

		gl.ActiveTexture(gl.TEXTURE3)
		gl.BindTexture(gl.TEXTURE_2D, ssao_blur_texture)

		gl.UseProgram(lighting_shader)
		shaders.set_int(lighting_shader, "g_position", 0)
		shaders.set_int(lighting_shader, "g_normal", 1)
		shaders.set_int(lighting_shader, "g_albedo", 2)
		shaders.set_int(lighting_shader, "ssao", 3)
		render.point_light_set_uniform(&light, lighting_shader)

		primitives.full_screen_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		primitives.full_screen_clear_from_gpu()
		render.scene_clear_from_gpu(&backpack_model)

		gl.DeleteTextures(NUM_G_BUFFERS, raw_data(g_buffers[:]))
		gl.DeleteTextures(1, &ssao_color_buffer)
		gl.DeleteTextures(1, &noise_texture)
		gl.DeleteRenderbuffers(1, &rbo)
		gl.DeleteFramebuffers(1, &g_buffer_fbo)
		gl.DeleteFramebuffers(1, &ssao_fbo)
	},
	framebuffer_size_callback = proc() {
		for i in 0 ..< NUM_G_BUFFERS {
			gl.BindTexture(gl.TEXTURE_2D, g_buffers[i])
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, window.width, window.height, 0, gl.RGBA, gl.FLOAT, nil)
		}

		gl.BindTexture(gl.TEXTURE_2D, ssao_color_buffer)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, window.width, window.height, 0, gl.RED, gl.FLOAT, nil)

		gl.BindTexture(gl.TEXTURE_2D, ssao_blur_texture)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, window.width, window.height, 0, gl.RED, gl.FLOAT, nil)

		gl.BindTexture(gl.TEXTURE_2D, 0)

		gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, window.width, window.height)
		gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
	},
}

@(private = "file")
generate_sample_offset :: proc(i: int) -> (sample: types.Vec3) {
	sample.x = rand.float32() * 2 - 1
	sample.y = rand.float32() * 2 - 1
	sample.z = rand.float32()

	sample = linalg.normalize(sample)
	sample *= rand.float32()
	scale := f32(i) / NUM_SAMPLES
	scale = math.lerp(f32(0.1), f32(1.0), scale * scale)
	sample *= scale
	return
}

@(private = "file")
generate_noise_vector :: proc() -> (noise: types.Vec3) {
	noise.x = rand.float32() * 2 - 1
	noise.y = rand.float32() * 2 - 1
	noise.z = 0
	return
}
