package chapter_06_pbr

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
INITIAL_CAMERA_POSITION :: types.Vec3{-1, -1, 22}

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

@(private = "file", rodata)
light_positions := [NUM_POINT_LIGHTS]types.Vec3{{-10, 10, 10}, {10, 10, 10}, {-10, -10, 10}, {10, -10, 10}}

@(private = "file", rodata)
light_colors := [NUM_POINT_LIGHTS]types.Vec3{{300, 300, 300}, {300, 300, 300}, {300, 300, 300}, {300, 300, 300}}

@(private = "file", rodata)
albedo := types.Vec3{0.5, 0, 0}

exercise_01_01_lighting :: types.Tableau {
	title = "PBR basic lighting",
	init = proc() {
		shaders.init_shaders(.PBR, .Light)
		primitives.sphere_init()
		primitives.sphere_send_to_gpu()

		camera = get_initial_camera()

		for row in 0 ..< NUM_ROWS {
			for column in 0 ..< NUM_COLUMNS {
				index := row * NUM_COLUMNS + column

				transforms[index] = linalg.matrix4_translate_f32(
					{f32(column) - (f32(NUM_COLUMNS) / 2), f32(row) - (f32(NUM_ROWS) / 2), 0} * SPACING,
				)

				mits[index] = types.SubTransformMatrix(linalg.inverse_transpose(transforms[index]))
			}
		}

		pbr_shader := shaders.shaders[.PBR]

		gl.UseProgram(pbr_shader)
		shaders.set_float(pbr_shader, "ao", 1)
		shaders.set_vec3(pbr_shader, "albedo", raw_data(&albedo))

		utils.print_gl_errors()
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
	},
	draw = proc() {
		pbr_shader := shaders.shaders[.PBR]
		light_shader := shaders.shaders[.Light]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		gl.UseProgram(pbr_shader)

		shaders.set_int(pbr_shader, "num_point_lights", NUM_POINT_LIGHTS)
		shaders.set_vec3(pbr_shader, "view_position", raw_data(&camera.position))

		for i in 0 ..< NUM_POINT_LIGHTS {
			shaders.set_vec3(pbr_shader, fmt.ctprintf("point_light_positions[{}]", i), raw_data(&light_positions[i]))
			shaders.set_vec3(pbr_shader, fmt.ctprintf("point_light_colors[{}]", i), raw_data(&light_colors[i]))
		}

		for row in 0 ..< NUM_ROWS {
			shaders.set_float(pbr_shader, "metallic", f32(row) / f32(NUM_ROWS))

			for column in 0 ..< NUM_COLUMNS {
				roughness := math.lerp(f32(0.5), f32(1.0), f32(column) / f32(NUM_COLUMNS))
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

		for i in 0 ..< NUM_POINT_LIGHTS {
			model := linalg.matrix4_translate_f32(light_positions[i])
			transform := pv * model

			shaders.set_mat_4x4(pbr_shader, "transform", raw_data(&transform))
			shaders.set_vec3(light_shader, "light_color", raw_data(&light_colors[i]))

			primitives.sphere_draw()
		}
	},
	teardown = proc() {
		primitives.sphere_clear_from_gpu()
		primitives.sphere_destroy()
	},
}
