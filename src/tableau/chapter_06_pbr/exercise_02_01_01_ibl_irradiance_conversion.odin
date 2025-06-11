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
transforms: [NUM_ROWS * NUM_COLUMNS]types.TransformMatrix

@(private = "file")
mits: [NUM_ROWS * NUM_COLUMNS]types.SubTransformMatrix

@(private = "file")
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
initial_camera_position := types.Vec3{-1, -1, 22}

@(private = "file")
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
pbr_material :: "rusted_iron"

@(private = "file")
albedo_map, normal_map, metallic_map, roughness_map, ao_map, ibl_map: render.Texture

exercise_02_01_01_ibl_irradiance_conversion := types.Tableau {
	init = proc() {
		shaders.init_shaders(.PBRTexture, .Light)
		primitives.sphere_init()
		primitives.sphere_send_to_gpu()

		for row in 0 ..< NUM_ROWS {
			for column in 0 ..< NUM_COLUMNS {
				index := row * NUM_COLUMNS + column

				transforms[index] = linalg.matrix4_translate_f32(
					{f32(column) - (f32(NUM_COLUMNS) / 2), f32(row) - (f32(NUM_ROWS) / 2), 0} * SPACING,
				)

				mits[index] = types.SubTransformMatrix(linalg.inverse_transpose(transforms[index]))
			}
		}

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

		ibl_map = render.prepare_hdr_texture("textures/hdr/newport_loft.hdr", .Diffuse, flip_vertically = true)

		pbr_shader := shaders.shaders[.PBRTexture]
		gl.UseProgram(pbr_shader)
		shaders.set_int(pbr_shader, "albedo_map", 0)
		shaders.set_int(pbr_shader, "normal_map", 1)
		shaders.set_int(pbr_shader, "metallic_map", 2)
		shaders.set_int(pbr_shader, "roughness_map", 3)
		shaders.set_int(pbr_shader, "ao_map", 4)
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
	},
	draw = proc() {
		pbr_shader := shaders.shaders[.PBRTexture]
		light_shader := shaders.shaders[.Light]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)

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

		gl.UseProgram(pbr_shader)

		shaders.set_int(pbr_shader, "num_point_lights", NUM_POINT_LIGHTS)
		shaders.set_vec3(pbr_shader, "view_position", raw_data(&camera.position))

		for i in 0 ..< NUM_POINT_LIGHTS {
			shaders.set_vec3(pbr_shader, fmt.ctprintf("point_light_positions[{}]", i), raw_data(&light_positions[i]))
			shaders.set_vec3(pbr_shader, fmt.ctprintf("point_light_colors[{}]", i), raw_data(&light_colors[i]))
		}

		for row in 0 ..< NUM_ROWS {
			// shaders.set_float(pbr_shader, "metallic", f32(row) / f32(NUM_ROWS))

			for column in 0 ..< NUM_COLUMNS {
				roughness := math.lerp(f32(0.5), f32(1.0), f32(column) / f32(NUM_COLUMNS))
				// shaders.set_float(pbr_shader, "roughness", roughness)

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

		for i in 0 ..< NUM_POINT_LIGHTS {
			model := linalg.matrix4_translate_f32(light_positions[i])
			transform := pv * model

			shaders.set_mat_4x4(light_shader, "transform", raw_data(&transform))
			shaders.set_vec3(light_shader, "light_color", raw_data(&light_colors[i]))
			shaders.set_bool(light_shader, "hdr", true)
			shaders.set_float(light_shader, "hdr_exposure", 0.005)

			primitives.sphere_draw()
		}
	},
	teardown = proc() {
		primitives.sphere_clear_from_gpu()
		primitives.sphere_destroy()

		gl.DeleteTextures(1, &albedo_map.id)
		gl.DeleteTextures(1, &normal_map.id)
		gl.DeleteTextures(1, &metallic_map.id)
		gl.DeleteTextures(1, &roughness_map.id)
		gl.DeleteTextures(1, &ao_map.id)
	},
}
