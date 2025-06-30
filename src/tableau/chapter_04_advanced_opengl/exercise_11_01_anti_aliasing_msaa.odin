package chapter_04_advanced_opengl

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec4{0.1, 0.1, 0.1, 1}

@(private = "file", rodata)
cube_color := types.Vec3{0, 1, 0}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{1.5, 1, 1.5}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{0, 0, 0}

@(private = "file")
get_initial_camera :: proc() -> render.Camera {
	return {
		type = .Flying,
		position = INITIAL_CAMERA_POSITION,
		direction = INITIAL_CAMERA_TARGET - INITIAL_CAMERA_POSITION,
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

exercise_11_01_anti_aliasing_msaa :: types.Tableau {
	title = "MSAA",
	init = proc() {
		shaders.init_shaders(.TransformUniformColor)
		primitives.cube_send_to_gpu()
		camera = get_initial_camera()
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
	},
	draw = proc() {
		single_color_shader := shaders.shaders[.TransformUniformColor]

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		transform := projection * view

		gl.UseProgram(single_color_shader)
		shaders.set_mat_4x4(single_color_shader, "transform", raw_data(&transform))
		shaders.set_vec4(single_color_shader, "our_color", raw_data(&cube_color))
		primitives.cube_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
	},
}
