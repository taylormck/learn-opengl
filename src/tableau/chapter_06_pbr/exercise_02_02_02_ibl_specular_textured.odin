package chapter_06_pbr

import "../../input"
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
import gl "vendor:OpenGL"

@(private = "file")
NUM_ROWS :: 7

@(private = "file")
NUM_COLUMNS :: 7

@(private = "file")
SPACING :: 2.5

@(private = "file")
CUBE_MAP_RESOLUTION :: 512

@(private = "file")
transforms: [NUM_ROWS * NUM_COLUMNS]types.TransformMatrix

@(private = "file")
mits: [NUM_ROWS * NUM_COLUMNS]types.SubTransformMatrix

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file", rodata)
initial_camera_position := types.Vec3{11, 2, 17}

@(private = "file", rodata)
initial_camera_target := types.Vec3{-1, -1, 0}

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
NUM_POINT_LIGHTS :: 4

@(private = "file")
light_positions := [NUM_POINT_LIGHTS]types.Vec3{{-10, 10, 10}, {10, 10, 10}, {-10, -10, 10}, {10, -10, 10}}

@(private = "file")
light_colors := [NUM_POINT_LIGHTS]types.Vec3{{700, 300, 300}, {300, 700, 300}, {300, 300, 700}, {700, 300, 700}}

@(private = "file")
env_cube_map, irradiance_map, prefilter_map: primitives.Cubemap

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
brdf_lut_texture := render.Texture {
	type = .Normal,
}

@(private = "file")
pbr_material :: "rusted_iron"
// pbr_material :: "gold"
// pbr_material :: "grass"
// pbr_material :: "plastic"
// pbr_material :: "wall"

@(private = "file")
albedo_map, normal_map, metallic_map, roughness_map, ao_map: render.Texture

@(private = "file")
display_irradiance := false

exercise_02_02_02_ibl_specular_textured := types.Tableau {
	init = proc() {
		shaders.init_shaders(
			.PBRFullTextured,
			.Light,
			.EquirectangularTexture,
			.SkyboxHDR,
			.CubemapConvolution,
			.CubemapPrefilter,
			.BRDFIntegration,
		)

		primitives.sphere_init()
		primitives.sphere_send_to_gpu()
		primitives.sphere_destroy()

		primitives.cubemap_send_to_gpu(&env_cube_map)
		primitives.cubemap_send_to_gpu(&irradiance_map)
		primitives.cubemap_send_to_gpu(&prefilter_map)
		primitives.cube_send_to_gpu()

		primitives.full_screen_send_to_gpu()

		defer gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		defer gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
		defer gl.Viewport(0, 0, window.width, window.height)

		log.info("Initializing sphere positions")
		for row in 0 ..< NUM_ROWS {
			for column in 0 ..< NUM_COLUMNS {
				index := row * NUM_COLUMNS + column

				transforms[index] = linalg.matrix4_translate_f32(
					{f32(column) - (f32(NUM_COLUMNS) / 2), f32(row) - (f32(NUM_ROWS) / 2), 0} * SPACING,
				)

				mits[index] = types.SubTransformMatrix(linalg.inverse_transpose(transforms[index]))
			}
		}

		log.debugf("Sphere positions: {}", transforms[:])
		log.debugf("Sphere MITs: {}", mits[:])

		log.infof("Loading PBR textures: textures/pbr/{}/...", pbr_material)

		albedo_map = render.prepare_texture(
			fmt.ctprintf("textures/pbr/{}/albedo.png", pbr_material),
			.Diffuse,
			flip_vertically = true,
			gamma_correction = true,
		)

		normal_map = render.prepare_texture(
			fmt.ctprintf("textures/pbr/{}/normal.png", pbr_material),
			.Normal,
			flip_vertically = true,
		)

		metallic_map = render.prepare_texture(
			fmt.ctprintf("textures/pbr/{}/metallic.png", pbr_material),
			.Metallic,
			flip_vertically = true,
		)

		roughness_map = render.prepare_texture(
			fmt.ctprintf("textures/pbr/{}/roughness.png", pbr_material),
			.Roughness,
			flip_vertically = true,
		)

		ao_map = render.prepare_texture(fmt.ctprintf("textures/pbr/{}/ao.png", pbr_material), .AO, flip_vertically = true)

		log.infof("Initializing constant PBR uniforms")
		pbr_shader := shaders.shaders[.PBRFullTextured]
		gl.UseProgram(pbr_shader)

		shaders.set_int(pbr_shader, "albedo_map", 0)
		shaders.set_int(pbr_shader, "normal_map", 1)
		shaders.set_int(pbr_shader, "metallic_map", 2)
		shaders.set_int(pbr_shader, "roughness_map", 3)
		shaders.set_int(pbr_shader, "ao_map", 4)
		shaders.set_int(pbr_shader, "irradiance_map", 5)
		shaders.set_int(pbr_shader, "prefilter_map", 6)
		shaders.set_int(pbr_shader, "brdf_lut", 7)

		ibl_map := render.prepare_hdr_texture("textures/hdr/newport_loft.hdr", .Diffuse, flip_vertically = true)
		// ibl_map := render.prepare_hdr_texture("textures/hdr/brown_photostudio.hdr", .Diffuse, flip_vertically = true)
		// ibl_map := render.prepare_hdr_texture("textures/hdr/warm_restaurant_night.hdr", .Diffuse, flip_vertically = true)
		// ibl_map := render.prepare_hdr_texture("textures/hdr/citrus_orchard_puresky.hdr", .Diffuse, flip_vertically = true)
		defer gl.DeleteTextures(1, &ibl_map.id)

		env_capture_fbo, env_capture_rbo: u32
		gl.GenFramebuffers(1, &env_capture_fbo)
		defer gl.DeleteFramebuffers(1, &env_capture_fbo)

		gl.GenRenderbuffers(1, &env_capture_rbo)
		defer gl.DeleteRenderbuffers(1, &env_capture_rbo)

		{
			log.info("Converting equirectangular environment map into cube map")

			gl.BindFramebuffer(gl.FRAMEBUFFER, env_capture_fbo)
			gl.BindRenderbuffer(gl.RENDERBUFFER, env_capture_rbo)

			gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, CUBE_MAP_RESOLUTION, CUBE_MAP_RESOLUTION)
			gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, env_capture_rbo)

			gl.GenTextures(1, &env_cube_map.texture_id)
			gl.BindTexture(gl.TEXTURE_CUBE_MAP, env_cube_map.texture_id)

			for i in 0 ..< 6 {
				gl.TexImage2D(
					gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i),
					0,
					gl.RGB16F,
					CUBE_MAP_RESOLUTION,
					CUBE_MAP_RESOLUTION,
					0,
					gl.RGB,
					gl.FLOAT,
					nil,
				)
			}

			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

			cubemap_shader := shaders.shaders[.EquirectangularTexture]

			gl.UseProgram(cubemap_shader)

			gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_2D, ibl_map.id)
			shaders.set_int(cubemap_shader, "equirectangular_map", 0)

			gl.Viewport(0, 0, CUBE_MAP_RESOLUTION, CUBE_MAP_RESOLUTION)

			gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
			for i in 0 ..< 6 {
				pv := env_capture_projection * env_capture_views[i]
				shaders.set_mat_4x4(cubemap_shader, "projection_view", raw_data(&pv))

				gl.FramebufferTexture2D(
					gl.FRAMEBUFFER,
					gl.COLOR_ATTACHMENT0,
					gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i),
					env_cube_map.texture_id,
					0,
				)

				gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

				primitives.cube_draw()
			}
			gl.GenerateMipmap(gl.TEXTURE_CUBE_MAP)
		}

		{
			log.info("Genereating convoluted environment map")

			gl.BindFramebuffer(gl.FRAMEBUFFER, env_capture_fbo)
			gl.BindRenderbuffer(gl.RENDERBUFFER, env_capture_rbo)

			gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, 32, 32)
			gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, env_capture_rbo)

			gl.GenTextures(1, &irradiance_map.texture_id)
			gl.BindTexture(gl.TEXTURE_CUBE_MAP, irradiance_map.texture_id)

			for i in 0 ..< 6 {
				gl.TexImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i), 0, gl.RGB16F, 32, 32, 0, gl.RGB, gl.FLOAT, nil)
			}

			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

			convolution_shader := shaders.shaders[.CubemapConvolution]

			gl.UseProgram(convolution_shader)

			gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_CUBE_MAP, env_cube_map.texture_id)

			shaders.set_int(convolution_shader, "environment_map", 0)

			gl.Viewport(0, 0, 32, 32)

			gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
			for i in 0 ..< 6 {
				pv := env_capture_projection * env_capture_views[i]
				shaders.set_mat_4x4(convolution_shader, "projection_view", raw_data(&pv))

				gl.FramebufferTexture2D(
					gl.FRAMEBUFFER,
					gl.COLOR_ATTACHMENT0,
					gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i),
					irradiance_map.texture_id,
					0,
				)

				gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

				primitives.cube_draw()
			}
		}

		{
			log.info("Generating prefiltered environment map")

			gl.BindFramebuffer(gl.FRAMEBUFFER, env_capture_fbo)
			gl.BindRenderbuffer(gl.RENDERBUFFER, env_capture_rbo)

			gl.GenTextures(1, &prefilter_map.texture_id)
			gl.BindTexture(gl.TEXTURE_CUBE_MAP, prefilter_map.texture_id)

			for i in 0 ..< 6 {
				gl.TexImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i), 0, gl.RGB16F, 128, 128, 0, gl.RGB, gl.FLOAT, nil)
			}

			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			gl.GenerateMipmap(gl.TEXTURE_CUBE_MAP)

			prefilter_shader := shaders.shaders[.CubemapPrefilter]
			gl.UseProgram(prefilter_shader)

			shaders.set_float(prefilter_shader, "cube_map_resolution", CUBE_MAP_RESOLUTION)

			gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_CUBE_MAP, env_cube_map.texture_id)
			shaders.set_int(prefilter_shader, "environment_map", 0)

			max_mip_levels :: 5
			gl.Enable(gl.TEXTURE_CUBE_MAP_SEAMLESS)

			for mip in 0 ..< max_mip_levels {
				mip_exp := f32(mip)
				mip_width := i32(128 * math.pow(0.5, mip_exp))
				mip_height := i32(128 * math.pow(0.5, mip_exp))

				gl.Viewport(0, 0, mip_width, mip_height)
				gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, mip_width, mip_height)

				roughness: f32 = mip_exp / f32(max_mip_levels - 1)
				shaders.set_float(prefilter_shader, "roughness", roughness)

				for i in 0 ..< 6 {
					pv := env_capture_projection * env_capture_views[i]
					shaders.set_mat_4x4(prefilter_shader, "projection_view", raw_data(&pv))

					gl.FramebufferTexture2D(
						gl.FRAMEBUFFER,
						gl.COLOR_ATTACHMENT0,
						gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i),
						prefilter_map.texture_id,
						i32(mip),
					)

					gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

					primitives.cube_draw()
				}
			}
		}

		{
			log.info("Generating BRDF integration map")
			integration_shader := shaders.shaders[.BRDFIntegration]
			gl.UseProgram(integration_shader)

			gl.GenTextures(1, &brdf_lut_texture.id)
			gl.BindTexture(gl.TEXTURE_2D, brdf_lut_texture.id)
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RG16F, CUBE_MAP_RESOLUTION, CUBE_MAP_RESOLUTION, 0, gl.RG, gl.FLOAT, nil)

			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

			gl.BindFramebuffer(gl.FRAMEBUFFER, env_capture_fbo)
			gl.BindRenderbuffer(gl.RENDERBUFFER, env_capture_rbo)
			gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, CUBE_MAP_RESOLUTION, CUBE_MAP_RESOLUTION)
			gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, brdf_lut_texture.id, 0)

			gl.Viewport(0, 0, CUBE_MAP_RESOLUTION, CUBE_MAP_RESOLUTION)
			gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

			primitives.full_screen_draw()
		}
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

		if .Space in input.input_state.pressed_keys do display_irradiance = !display_irradiance
	},
	draw = proc() {
		pbr_shader := shaders.shaders[.PBRFullTextured]
		light_shader := shaders.shaders[.Light]
		skybox_shader := shaders.shaders[.SkyboxHDR]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)
		gl.DepthFunc(gl.LEQUAL)

		gl.UseProgram(pbr_shader)

		shaders.set_int(pbr_shader, "num_point_lights", NUM_POINT_LIGHTS)
		shaders.set_vec3(pbr_shader, "view_position", raw_data(&camera.position))

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, albedo_map.id)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, normal_map.id)
		gl.ActiveTexture(gl.TEXTURE2)
		gl.BindTexture(gl.TEXTURE_2D, metallic_map.id)
		gl.ActiveTexture(gl.TEXTURE3)
		gl.BindTexture(gl.TEXTURE_2D, roughness_map.id)
		gl.ActiveTexture(gl.TEXTURE4)
		gl.BindTexture(gl.TEXTURE_2D, ao_map.id)

		gl.ActiveTexture(gl.TEXTURE5)
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, irradiance_map.texture_id)

		gl.ActiveTexture(gl.TEXTURE6)
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, prefilter_map.texture_id)

		gl.ActiveTexture(gl.TEXTURE7)
		gl.BindTexture(gl.TEXTURE_2D, brdf_lut_texture.id)

		for i in 0 ..< NUM_POINT_LIGHTS {
			shaders.set_vec3(pbr_shader, fmt.ctprintf("point_light_positions[{}]", i), raw_data(&light_positions[i]))
			shaders.set_vec3(pbr_shader, fmt.ctprintf("point_light_colors[{}]", i), raw_data(&light_colors[i]))
		}

		for i in 0 ..< NUM_COLUMNS * NUM_ROWS {
			model := &transforms[i]
			transform := pv * model^
			mit := &mits[i]

			shaders.set_mat_4x4(pbr_shader, "transform", raw_data(&transform))
			shaders.set_mat_4x4(pbr_shader, "model", raw_data(model))
			shaders.set_mat_3x3(pbr_shader, "mit", raw_data(mit))

			primitives.sphere_draw()
		}

		gl.UseProgram(light_shader)

		for i in 0 ..< NUM_POINT_LIGHTS {
			model := linalg.matrix4_translate_f32(light_positions[i])
			transform := pv * model

			shaders.set_mat_4x4(light_shader, "transform", raw_data(&transform))
			shaders.set_vec3(light_shader, "light_color", raw_data(&light_colors[i]))
			shaders.set_bool(light_shader, "hdr", true)
			shaders.set_float(light_shader, "hdr_exposure", 0.005)

			primitives.sphere_draw()
		}

		// Draw the skybox
		rot_view := types.TransformMatrix(types.SubTransformMatrix(view))
		projection_rot_view := projection * rot_view

		gl.UseProgram(skybox_shader)
		shaders.set_mat_4x4(skybox_shader, "projection_view", raw_data(&projection_rot_view))
		shaders.set_int(skybox_shader, "skybox", 0)

		if display_irradiance {primitives.cubemap_draw(&prefilter_map)} else {primitives.cubemap_draw(&env_cube_map)}
	},
	teardown = proc() {
		gl.DeleteTextures(1, &brdf_lut_texture.id)
		primitives.full_screen_clear_from_gpu()

		primitives.cubemap_clear_from_gpu(&env_cube_map)
		primitives.cubemap_destroy_texture(&env_cube_map)
		primitives.cubemap_clear_from_gpu(&irradiance_map)
		primitives.cubemap_destroy_texture(&irradiance_map)
		primitives.cubemap_clear_from_gpu(&prefilter_map)
		primitives.cubemap_destroy_texture(&prefilter_map)

		primitives.sphere_clear_from_gpu()

		gl.DeleteTextures(1, &albedo_map.id)
		gl.DeleteTextures(1, &normal_map.id)
		gl.DeleteTextures(1, &metallic_map.id)
		gl.DeleteTextures(1, &roughness_map.id)
		gl.DeleteTextures(1, &ao_map.id)
	},
}
