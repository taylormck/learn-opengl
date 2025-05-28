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
initial_camera_position := types.Vec3{0, 0, 4}

@(private = "file")
initial_camera_target := types.Vec3{0, 0, 0}

@(private = "file")
ubo: u32

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
NUM_COLORS :: 4

@(private = "file")
color_shaders: [NUM_COLORS]u32

@(private = "file")
cube_offsets := [NUM_COLORS]types.TransformMatrix {
	linalg.matrix4_translate_f32({-0.75, 0.75, 0}),
	linalg.matrix4_translate_f32({0.75, 0.75, 0}),
	linalg.matrix4_translate_f32({-0.75, -0.75, 0}),
	linalg.matrix4_translate_f32({0.75, -0.75, 0}),
}

exercise_08_01_advanced_glsl_ubo := types.Tableau {
	init = proc() {
		primitives.cube_send_to_gpu()
		shaders.init_shaders(.UboRed, .UboGreen, .UboBlue, .UboYellow)

		color_shaders = [NUM_COLORS]u32 {
			shaders.shaders[.UboRed],
			shaders.shaders[.UboGreen],
			shaders.shaders[.UboBlue],
			shaders.shaders[.UboYellow],
		}

		for shader in color_shaders {
			ubo_index := gl.GetUniformBlockIndex(shader, "Matrices")
			gl.UniformBlockBinding(shader, ubo_index, 0)
		}

		gl.GenBuffers(1, &ubo)
		gl.BindBuffer(gl.UNIFORM_BUFFER, ubo)
		gl.BufferData(gl.UNIFORM_BUFFER, size_of(types.TransformMatrix), nil, gl.STATIC_DRAW)
		gl.BindBuffer(gl.UNIFORM_BUFFER, 0)

		gl.BindBufferRange(gl.UNIFORM_BUFFER, 0, ubo, 0, size_of(types.TransformMatrix))
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

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.BindBuffer(gl.UNIFORM_BUFFER, ubo)
		gl.BufferSubData(gl.UNIFORM_BUFFER, 0, size_of(types.TransformMatrix), raw_data(&pv))
		gl.BindBuffer(gl.UNIFORM_BUFFER, 0)

		for i in 0 ..< NUM_COLORS {
			shader := color_shaders[i]
			model := cube_offsets[i]

			gl.UseProgram(shader)
			gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "model"), 1, false, raw_data(&model))
			primitives.cube_draw()
		}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		gl.DeleteBuffers(1, &ubo)
	},
}
