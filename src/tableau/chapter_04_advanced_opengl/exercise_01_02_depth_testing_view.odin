package chapter_04_advanced_opengl

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
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
initial_camera_position := types.Vec3{4.5, 0.6, -0.3}

@(private = "file")
initial_camera_target := types.Vec3{0, 0, 0}

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

exercise_01_02_depth_testing_view := types.Tableau {
	init = proc() {
		shaders.init_shaders(.Depth)
		primitives.cube_send_to_gpu()
		primitives.quad_send_to_gpu()
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
	},
	draw = proc() {
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		depth_shader := shaders.shaders[.Depth]

		gl.Uniform1i(gl.GetUniformLocation(depth_shader, "diffuse_0"), 0)
		gl.UseProgram(depth_shader)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		// Draw cubes first
		{
			cube_positions := [?]types.Vec3{{-1, 0, -1}, {2, 0, 0}}
			for position in cube_positions {
				model := linalg.matrix4_translate(position)
				transform := pv * model

				gl.UniformMatrix4fv(gl.GetUniformLocation(depth_shader, "transform"), 1, false, raw_data(&transform))

				primitives.cube_draw()
			}
		}

		{
			// Draw floor
			model := linalg.matrix4_translate(types.Vec3{0, -0.5, 0})
			model = model * linalg.matrix4_rotate(linalg.to_radians(f32(-90)), types.Vec3{1, 0, 0})
			model = linalg.matrix4_scale_f32(types.Vec3{10, 1, 10}) * model
			transform := pv * model

			gl.UniformMatrix4fv(gl.GetUniformLocation(depth_shader, "transform"), 1, false, raw_data(&transform))

			primitives.quad_draw()
		}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		primitives.quad_clear_from_gpu()
	},
}
