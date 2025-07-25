package chapter_06_pbr

import "../../input"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../utils"
import "../../window"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
NUM_ROWS :: 7

@(private = "file")
NUM_COLUMNS :: 7

@(private = "file")
SPACING :: 2.5

@(private = "file")
transforms: [NUM_ROWS * NUM_COLUMNS]types.TransformMatrix

@(private = "file")
mits: [NUM_ROWS * NUM_COLUMNS]types.SubTransformMatrix

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{11, 2, 17}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{-1, -1, 0}

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
NUM_POINT_LIGHTS :: 4

@(private = "file")
light_positions := [NUM_POINT_LIGHTS]types.Vec3{{-10, 10, 10}, {10, 10, 10}, {-10, -10, 10}, {10, -10, 10}}

@(private = "file")
light_colors := [NUM_POINT_LIGHTS]types.Vec3{{700, 300, 300}, {300, 700, 300}, {300, 300, 700}, {700, 300, 700}}

@(private = "file")
env_cube_map, irradiance_map: u32

@(private = "file")
env_capture_projection := linalg.matrix4_perspective_f32(
	fovy = linalg.to_radians(f32(90.0)),
	aspect = 1,
	near = 0.1,
	far = 10,
)

@(private = "file")
CENTER :: types.Vec3{0, 0, 0}

@(private = "file")
env_capture_views := [6]types.TransformMatrix {
	linalg.matrix4_look_at_f32(CENTER, {1, 0, 0}, {0, -1, 0}),
	linalg.matrix4_look_at_f32(CENTER, {-1, 0, 0}, {0, -1, 0}),
	linalg.matrix4_look_at_f32(CENTER, {0, 1, 0}, {0, 0, 1}),
	linalg.matrix4_look_at_f32(CENTER, {0, -1, 0}, {0, 0, -1}),
	linalg.matrix4_look_at_f32(CENTER, {0, 0, 1}, {0, -1, 0}),
	linalg.matrix4_look_at_f32(CENTER, {0, 0, -1}, {0, -1, 0}),
}


@(private = "file")
albedo := types.Vec3{0.7, 0.3, 0.5}

@(private = "file")
display_irradiance := false

exercise_02_01_02_ibl_irradiance :: types.Tableau {
	title = "PBR with environment-mapped diffuse lighting",
	help_text = "Spress [SPACE] to toggle debug view of convoluted environment map.",
	init = proc() {
		shaders.init_shaders(.PBRIrradiance, .Light, .EquirectangularTexture, .SkyboxHDR, .CubemapConvolution)

		primitives.sphere_init()
		primitives.sphere_send_to_gpu()
		primitives.sphere_destroy()

		primitives.cubemap_send_to_gpu()
		primitives.cube_send_to_gpu()

		camera = get_initial_camera()

		defer gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		defer gl.BindRenderbuffer(gl.RENDERBUFFER, 0)

		for row in 0 ..< NUM_ROWS {
			for column in 0 ..< NUM_COLUMNS {
				index := row * NUM_COLUMNS + column

				transforms[index] = linalg.matrix4_translate_f32(
					{f32(column) - (f32(NUM_COLUMNS) / 2), f32(row) - (f32(NUM_ROWS) / 2), 0} * SPACING,
				)

				mits[index] = types.SubTransformMatrix(linalg.inverse_transpose(transforms[index]))
			}
		}

		pbr_shader := shaders.shaders[.PBRIrradiance]
		gl.UseProgram(pbr_shader)
		shaders.set_float(pbr_shader, "ao", 1)
		shaders.set_vec3(pbr_shader, "albedo", raw_data(&albedo))

		ibl_map := render.prepare_hdr_texture("textures/hdr/newport_loft.hdr", .Diffuse, flip_vertically = true)
		// ibl_map := render.prepare_hdr_texture("textures/hdr/citrus_orchard_puresky.hdr", .Diffuse, flip_vertically = true)
		defer gl.DeleteTextures(1, &ibl_map.id)

		env_capture_fbo, env_capture_rbo: u32
		{
			gl.GenFramebuffers(1, &env_capture_fbo)
			defer gl.DeleteFramebuffers(1, &env_capture_fbo)

			gl.GenRenderbuffers(1, &env_capture_rbo)
			defer gl.DeleteRenderbuffers(1, &env_capture_rbo)

			gl.BindFramebuffer(gl.FRAMEBUFFER, env_capture_fbo)
			gl.BindRenderbuffer(gl.RENDERBUFFER, env_capture_rbo)

			gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, 512, 512)
			gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, env_capture_rbo)

			// Create cube map textures.
			gl.GenTextures(1, &env_cube_map)
			gl.BindTexture(gl.TEXTURE_CUBE_MAP, env_cube_map)

			for i in 0 ..< 6 {
				gl.TexImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i), 0, gl.RGB16F, 512, 512, 0, gl.RGB, gl.FLOAT, nil)
			}

			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

			// Convert the equirectangular env map a cube map.
			cubemap_shader := shaders.shaders[.EquirectangularTexture]

			gl.UseProgram(cubemap_shader)

			gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_2D, ibl_map.id)
			shaders.set_int(cubemap_shader, "equirectangular_map", 0)

			gl.Viewport(0, 0, 512, 512)
			defer gl.Viewport(0, 0, window.width, window.height)

			gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
			for i in 0 ..< 6 {
				pv := env_capture_projection * env_capture_views[i]
				shaders.set_mat_4x4(cubemap_shader, "projection_view", raw_data(&pv))

				gl.FramebufferTexture2D(
					gl.FRAMEBUFFER,
					gl.COLOR_ATTACHMENT0,
					gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i),
					env_cube_map,
					0,
				)

				gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

				primitives.cube_draw()
			}
		}

		{
			// Convolute the Irradiance map
			gl.GenFramebuffers(1, &env_capture_fbo)
			defer gl.DeleteFramebuffers(1, &env_capture_fbo)

			gl.GenRenderbuffers(1, &env_capture_rbo)
			defer gl.DeleteRenderbuffers(1, &env_capture_rbo)

			gl.BindFramebuffer(gl.FRAMEBUFFER, env_capture_fbo)
			gl.BindRenderbuffer(gl.RENDERBUFFER, env_capture_rbo)

			gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, 32, 32)
			gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, env_capture_rbo)

			// Create cube map textures.
			gl.GenTextures(1, &irradiance_map)
			gl.BindTexture(gl.TEXTURE_CUBE_MAP, irradiance_map)

			for i in 0 ..< 6 {
				gl.TexImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i), 0, gl.RGB16F, 32, 32, 0, gl.RGB, gl.FLOAT, nil)
			}

			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

			// Convert the equirectangular env map a cube map.
			convolution_shader := shaders.shaders[.CubemapConvolution]

			gl.UseProgram(convolution_shader)

			gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_CUBE_MAP, env_cube_map)

			shaders.set_int(convolution_shader, "environment_map", 0)

			gl.Viewport(0, 0, 32, 32)
			defer gl.Viewport(0, 0, window.width, window.height)

			gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
			for i in 0 ..< 6 {
				pv := env_capture_projection * env_capture_views[i]
				shaders.set_mat_4x4(convolution_shader, "projection_view", raw_data(&pv))

				gl.FramebufferTexture2D(
					gl.FRAMEBUFFER,
					gl.COLOR_ATTACHMENT0,
					gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i),
					irradiance_map,
					0,
				)

				gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

				primitives.cube_draw()
			}
		}

		utils.print_gl_errors()
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)

		if .Space in input.input_state.pressed_keys do display_irradiance = !display_irradiance
	},
	draw = proc() {
		pbr_shader := shaders.shaders[.PBRIrradiance]
		light_shader := shaders.shaders[.Light]
		skybox_shader := shaders.shaders[.SkyboxHDR]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		gl.DepthFunc(gl.LEQUAL)

		gl.UseProgram(pbr_shader)

		shaders.set_int(pbr_shader, "num_point_lights", NUM_POINT_LIGHTS)
		shaders.set_vec3(pbr_shader, "view_position", raw_data(&camera.position))

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, irradiance_map)
		shaders.set_int(pbr_shader, "irradiance_map", 0)

		for i in 0 ..< NUM_POINT_LIGHTS {
			shaders.set_vec3(pbr_shader, fmt.ctprintf("point_light_positions[{}]", i), raw_data(&light_positions[i]))
			shaders.set_vec3(pbr_shader, fmt.ctprintf("point_light_colors[{}]", i), raw_data(&light_colors[i]))
		}

		for row in 0 ..< NUM_ROWS {
			shaders.set_float(pbr_shader, "metallic", f32(row) / f32(NUM_ROWS))

			for column in 0 ..< NUM_COLUMNS {
				roughness := math.lerp(f32(0.1), f32(1.0), f32(column) / f32(NUM_COLUMNS))
				shaders.set_float(pbr_shader, "roughness", roughness)

				index := row * NUM_COLUMNS + column

				model := &transforms[index]
				transform := pv * model^
				mit := &mits[index]

				shaders.set_mat_4x4(pbr_shader, "transform", raw_data(&transform))
				shaders.set_mat_4x4(pbr_shader, "model", raw_data(model))
				shaders.set_mat_3x3(pbr_shader, "mit", raw_data(mit))

				primitives.sphere_draw()
			}
		}

		gl.UseProgram(light_shader)

		shaders.set_bool(light_shader, "hdr", true)
		shaders.set_float(light_shader, "hdr_exposure", 0.005)

		for i in 0 ..< NUM_POINT_LIGHTS {
			model := linalg.matrix4_translate_f32(light_positions[i])
			transform := pv * model

			shaders.set_mat_4x4(light_shader, "transform", raw_data(&transform))
			shaders.set_vec3(light_shader, "light_color", raw_data(&light_colors[i]))

			primitives.sphere_draw()
		}

		shaders.set_bool(light_shader, "hdr", false)

		// Draw the skybox
		rot_view := types.TransformMatrix(types.SubTransformMatrix(view))
		projection_rot_view := projection * rot_view

		gl.UseProgram(skybox_shader)
		shaders.set_mat_4x4(skybox_shader, "projection_view", raw_data(&projection_rot_view))
		shaders.set_int(skybox_shader, "skybox", 0)

		if display_irradiance {primitives.cubemap_draw(irradiance_map)} else {primitives.cubemap_draw(env_cube_map)}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		primitives.cubemap_clear_from_gpu()
		primitives.sphere_clear_from_gpu()

		gl.DeleteTextures(1, &env_cube_map)
		gl.DeleteTextures(1, &irradiance_map)
	},
}
