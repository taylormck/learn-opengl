package chapter_01_getting_started

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
get_initial_camera :: proc() -> render.Camera {
	return {
		type = .Flying,
		position = {0, 0, 3},
		direction = {0, 0, -1},
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
time: f64

@(private = "file")
container_texture, awesome_texture: render.Texture

exercise_06_02_coordinate_systems_depth :: types.Tableau {
	title = "Cube",
	init = proc() {
		shaders.init_shaders(.TransformDoubleTexture)
		container_texture = render.prepare_texture("textures/container.png", .Diffuse, true)
		awesome_texture = render.prepare_texture("textures/awesomeface.png", .Diffuse, true)
		primitives.cube_send_to_gpu()
		time = 0
		camera = get_initial_camera()
	},
	update = proc(delta: f64) {
		time += delta
		camera.aspect_ratio = window.aspect_ratio()
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, awesome_texture.id)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)

		texture_shader := shaders.shaders[.TransformDoubleTexture]
		gl.UseProgram(texture_shader)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		model := linalg.matrix4_rotate_f32(f32(time * linalg.to_radians(50.0)), {0.5, 1, 0})
		transform := projection * view * model

		shaders.set_int(texture_shader, "diffuse_0", 0)
		shaders.set_int(texture_shader, "diffuse_1", 1)

		shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

		primitives.cube_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
	},
}
