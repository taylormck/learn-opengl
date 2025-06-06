package chapter_05_advanced_lighting

import "../../input"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

@(private = "file")
background_color := types.Vec3{0, 0, 0}

@(private = "file")
initial_camera_position := types.Vec3{5, -0.5, 4}

@(private = "file")
initial_camera_target := types.Vec3{0, 1, 0.5}

@(private = "file")
camera := render.Camera {
	type         = .Flying,
	position     = initial_camera_position,
	direction    = initial_camera_target - initial_camera_position,
	up           = {0, 1, 0},
	fov          = linalg.to_radians(f32(45)),
	aspect_ratio = window.aspect_ratio(),
	near         = 0.1,
	far          = 1000,
	speed        = 5,
}

@(private = "file")
WHITE :: types.Vec3{1, 1, 1}

@(private = "file")
RED :: types.Vec3{1, 0, 0}

@(private = "file")
GREEN :: types.Vec3{0, 1, 0}

@(private = "file")
BLUE :: types.Vec3{0, 0, 1}

@(private = "file")
lights := [?]render.PointLight {
	{
		position = {0, 0.5, 1.5},
		ambient = WHITE * 0.5,
		diffuse = WHITE * 5,
		specular = WHITE * 5,
		emissive = WHITE * 6,
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {-4, 0.5, -3},
		ambient = RED * 1,
		diffuse = RED * 10,
		specular = RED * 10,
		emissive = RED * 10 + WHITE,
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {-0.8, 2.4, -1},
		ambient = GREEN * 0.1,
		diffuse = GREEN * 5,
		specular = GREEN * 5,
		emissive = GREEN * 5 + WHITE,
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {3, 0.5, 1},
		ambient = BLUE * 0.1,
		diffuse = BLUE * 15,
		specular = BLUE * 15,
		emissive = BLUE * 15 + WHITE,
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
}

@(private = "file")
wood_shininess: f32 = 64

@(private = "file")
wood_specular := types.Vec3{0.5, 0.5, 0.5}

@(private = "file")
wood_texture: render.Texture

@(private = "file")
container_diffuse, container_specular: render.Texture

@(private = "file")
hdr_fbo, hdr_rbo: u32

@(private = "file")
hdr_fb_textures: [2]u32

@(private = "file")
color_attachments := [?]u32{gl.COLOR_ATTACHMENT0, gl.COLOR_ATTACHMENT1}

@(private = "file")
ping_pong_fbos, ping_pong_fbo_textures: [2]u32

@(private = "file")
hdr := true

@(private = "file")
reinhard := false

@(private = "file")
exposure: f32 = 1.0

@(private = "file")
bloom := true

@(private = "file")
floor_model := linalg.matrix4_translate_f32({0, -0.5, 0})

@(private = "file")
floor_mit: types.SubTransformMatrix

@(private = "file")
cube_models := [?]types.TransformMatrix {
	linalg.matrix4_translate_f32({0, 1.5, 0}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({2, 0, 1}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({-1, -1, 2}) *
	linalg.matrix4_rotate(linalg.to_radians(f32(60)), linalg.normalize(types.Vec3{1, 0, 1})),
	linalg.matrix4_translate_f32({0, 2.7, 4}) *
	linalg.matrix4_rotate(linalg.to_radians(f32(23)), linalg.normalize(types.Vec3{1, 0, 1})) *
	linalg.matrix4_scale_f32(1.25),
	linalg.matrix4_translate_f32({-2, 1, -3}) *
	linalg.matrix4_rotate(linalg.to_radians(f32(124)), linalg.normalize(types.Vec3{1, 0, 1})),
	linalg.matrix4_translate_f32({-3, 0, 0}) * linalg.matrix4_scale_f32(0.5),
}

@(private = "file")
cube_mits := [len(cube_models)]types.SubTransformMatrix{}

// Blur the bright framebuffer
BLUR_AMOUNT :: 10

exercise_07_01_bloom := types.Tableau {
	init = proc() {
		shaders.init_shaders(.BloomLighting, .HDR, .Light, .BlurSeparated)
		wood_texture = render.prepare_texture(
			"textures/wood.png",
			.Diffuse,
			flip_vertically = true,
			gamma_correction = true,
		)

		container_diffuse = render.prepare_texture(
			"textures/container2.png",
			.Diffuse,
			flip_vertically = true,
			gamma_correction = true,
		)

		container_specular = render.prepare_texture(
			"textures/container2_specular.png",
			.Diffuse,
			flip_vertically = true,
			gamma_correction = false,
		)

		primitives.cube_send_to_gpu()
		primitives.plane_send_to_gpu()
		primitives.full_screen_send_to_gpu()

		gl.GenFramebuffers(1, &hdr_fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, hdr_fbo)

		gl.GenTextures(len(hdr_fb_textures), raw_data(hdr_fb_textures[:]))

		for tex, i in hdr_fb_textures {
			gl.BindTexture(gl.TEXTURE_2D, tex)
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, window.width, window.height, 0, gl.RGBA, gl.FLOAT, nil)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0 + u32(i), gl.TEXTURE_2D, tex, 0)
		}

		gl.BindTexture(gl.TEXTURE_2D, 0)

		gl.GenRenderbuffers(1, &hdr_rbo)
		gl.BindRenderbuffer(gl.RENDERBUFFER, hdr_rbo)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, window.width, window.height)
		gl.BindRenderbuffer(gl.RENDERBUFFER, 0)

		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, hdr_rbo)

		gl.DrawBuffers(2, raw_data(color_attachments[:]))

		ensure(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE, "Framebuffer incomplete!")

		gl.GenFramebuffers(2, raw_data(ping_pong_fbos[:]))
		gl.GenTextures(2, raw_data(ping_pong_fbo_textures[:]))
		for tex, i in ping_pong_fbo_textures {
			gl.BindFramebuffer(gl.FRAMEBUFFER, ping_pong_fbos[i])
			gl.BindTexture(gl.TEXTURE_2D, tex)
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, window.width, window.height, 0, gl.RGBA, gl.FLOAT, nil)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex, 0)

			ensure(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE, "Framebuffer incomplete!")
		}

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

		floor_mit = types.SubTransformMatrix(linalg.inverse_transpose(floor_model))

		for model, i in cube_models {
			cube_mits[i] = types.SubTransformMatrix(linalg.inverse_transpose(model))
		}

		scene_shader := shaders.shaders[.BloomLighting]
		gl.UseProgram(scene_shader)
		shaders.set_int(scene_shader, "num_point_lights", len(lights))
		for &light, i in lights do render.point_light_array_set_uniform(&light, scene_shader, u32(i))

		shaders.set_int(scene_shader, "material.diffuse_0", 0)
		shaders.set_vec3(scene_shader, "material.specular", raw_data(&wood_specular))
		shaders.set_float(scene_shader, "material.shininess", wood_shininess)
		shaders.set_bool(scene_shader, "invert_normals", false)

		// shaders.set_bool(scene_shader, "gamma", false)
		// shaders.set_bool(scene_shader, "full_attenuation", false)

		full_screen_shader := shaders.shaders[.HDR]
		gl.UseProgram(full_screen_shader)
		shaders.set_bool(full_screen_shader, "hdr", hdr)
		shaders.set_bool(full_screen_shader, "linearize", false)
		shaders.set_bool(full_screen_shader, "reinhard", reinhard)
		shaders.set_float(full_screen_shader, "exposure", exposure)
		shaders.set_bool(full_screen_shader, "bloom", bloom)
	},
	update = proc(delta: f64) {
		camera.aspect_ratio = window.aspect_ratio()

		render.camera_move(&camera, input.input_state.movement, f32(delta))
		render.camera_update_direction(&camera, input.input_state.mouse.offset)
		camera.fov = clamp(
			camera.fov - input.input_state.mouse.scroll_offset,
			linalg.to_radians(f32(1)),
			linalg.to_radians(f32(45)),
		)

		full_screen_shader := shaders.shaders[.HDR]
		gl.UseProgram(full_screen_shader)

		if .Space in input.input_state.pressed_keys {
			hdr = !hdr
			shaders.set_bool(full_screen_shader, "hdr", hdr)
		}

		if .B in input.input_state.pressed_keys {
			reinhard = !reinhard
			shaders.set_bool(full_screen_shader, "reinhard", reinhard)
		}

		if .V in input.input_state.pressed_keys {
			bloom = !bloom
			shaders.set_bool(full_screen_shader, "bloom", bloom)
		}

		if .UpArrow in input.input_state.pressed_keys {
			exposure = clamp(exposure + 0.5, 0.1, 5.0)
			shaders.set_float(full_screen_shader, "exposure", exposure)
		}

		if .DownArrow in input.input_state.pressed_keys {
			exposure = clamp(exposure - 0.5, 0.1, 5.0)
			shaders.set_float(full_screen_shader, "exposure", exposure)
		}

	},
	draw = proc() {
		scene_shader := shaders.shaders[.BloomLighting]
		full_screen_shader := shaders.shaders[.HDR]
		light_shader := shaders.shaders[.Light]
		blur_shader := shaders.shaders[.BlurSeparated]

		gl.BindFramebuffer(gl.FRAMEBUFFER, hdr_fbo)
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.UseProgram(light_shader)
		for &light in lights {
			model := linalg.matrix4_translate(light.position) * linalg.matrix4_scale_f32(0.25)
			transform := pv * model

			shaders.set_mat_4x4(light_shader, "transform", raw_data(&transform))
			shaders.set_vec3(light_shader, "light_color", raw_data(&light.emissive))
			primitives.cube_draw()
		}

		gl.UseProgram(scene_shader)
		shaders.set_vec3(scene_shader, "view_position", raw_data(&camera.position))

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, container_diffuse.id)
		for &model, i in cube_models {
			transform := pv * model
			mit := &cube_mits[i]

			shaders.set_mat_4x4(scene_shader, "transform", raw_data(&transform))
			shaders.set_mat_4x4(scene_shader, "model", raw_data(&model))
			shaders.set_mat_3x3(scene_shader, "mit", raw_data(mit))
			primitives.cube_draw()
		}

		// Draw the floor
		{
			transform := pv * floor_model
			shaders.set_mat_4x4(scene_shader, "transform", raw_data(&transform))
			shaders.set_mat_4x4(scene_shader, "model", raw_data(&floor_model))
			shaders.set_mat_3x3(scene_shader, "mit", raw_data(&floor_mit))

			gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_2D, wood_texture.id)

			primitives.plane_draw()
		}

		gl.UseProgram(blur_shader)
		shaders.set_int(blur_shader, "image", 0)

		for i in 0 ..< BLUR_AMOUNT {
			in_index := i % 2
			out_index := 1 - in_index

			framebuffer := ping_pong_fbos[out_index]
			tex := ping_pong_fbo_textures[in_index]

			gl.BindFramebuffer(gl.FRAMEBUFFER, framebuffer)
			gl.BindTexture(gl.TEXTURE_2D, hdr_fb_textures[1] if i == 0 else tex)

			shaders.set_bool(blur_shader, "horizontal", in_index == 0)

			primitives.full_screen_draw()
		}

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.ClearColor(1, 1, 1, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.Disable(gl.DEPTH_TEST)

		gl.UseProgram(full_screen_shader)

		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, hdr_fb_textures[0])
		shaders.set_int(full_screen_shader, "hdr_buffer", 1)

		gl.ActiveTexture(gl.TEXTURE2)
		gl.BindTexture(gl.TEXTURE_2D, ping_pong_fbo_textures[BLUR_AMOUNT % 2])
		shaders.set_int(full_screen_shader, "bright_buffer", 2)

		primitives.full_screen_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		primitives.plane_clear_from_gpu()
		primitives.full_screen_clear_from_gpu()

		gl.DeleteTextures(1, &wood_texture.id)
		gl.DeleteTextures(1, &container_diffuse.id)
		gl.DeleteTextures(1, &container_specular.id)

		gl.DeleteTextures(len(hdr_fb_textures), raw_data(hdr_fb_textures[:]))
		gl.DeleteFramebuffers(1, &hdr_fbo)
		gl.DeleteRenderbuffers(1, &hdr_rbo)
	},
	framebuffer_size_callback = proc() {
		defer gl.BindTexture(gl.TEXTURE_2D, 0)
		for tex in hdr_fb_textures {
			gl.BindTexture(gl.TEXTURE_2D, tex)
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, window.width, window.height, 0, gl.RGBA, gl.FLOAT, nil)
			// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
			// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		}

		gl.BindRenderbuffer(gl.RENDERBUFFER, hdr_rbo)
		defer gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
		gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, window.width, window.height)

		for tex in ping_pong_fbo_textures {
			gl.BindTexture(gl.TEXTURE_2D, tex)
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, window.width, window.height, 0, gl.RGBA, gl.FLOAT, nil)
			// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
			// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		}

		camera.aspect_ratio = window.aspect_ratio()
	},
}
