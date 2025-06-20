package chapter_02_lighting

import "../../input"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
initial_camera_position := types.Vec3{1, 1.5, 4}

@(private = "file")
camera := render.Camera {
	type         = .Flying,
	position     = initial_camera_position,
	direction    = linalg.normalize(-initial_camera_position),
	up           = {0, 1, 0},
	fov          = linalg.to_radians(f32(45)),
	aspect_ratio = window.aspect_ratio(),
	near         = 0.1,
	far          = 1000,
	speed        = 5,
}

@(private = "file")
light_position := types.Vec3{1.2, 1, 2}

@(private = "file")
light_color := types.Vec3{1, 1, 1}

@(private = "file")
obj_color := types.Vec3{1, 0.5, 0.31}

@(private = "file")
cube_position := types.Vec3{}

exercise_01_01_colors :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.Light, .ObjLightColor)
		primitives.cube_send_to_gpu()
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
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		light_shader := shaders.shaders[.Light]
		obj_shader := shaders.shaders[.ObjLightColor]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		model := linalg.matrix4_translate(light_position)
		model *= linalg.matrix4_scale_f32(0.2)
		transform := pv * model

		gl.UseProgram(light_shader)

		shaders.set_vec3(light_shader, "light_color", raw_data(&light_color))
		shaders.set_mat_4x4(light_shader, "transform", raw_data(&transform))

		primitives.cube_draw()

		model = linalg.matrix4_translate(cube_position)
		transform = pv * model

		gl.UseProgram(obj_shader)

		shaders.set_vec3(obj_shader, "light_color", raw_data(&light_color))
		shaders.set_vec3(obj_shader, "object_color", raw_data(&obj_color))
		shaders.set_mat_4x4(obj_shader, "transform", raw_data(&transform))

		primitives.cube_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
	},
}
