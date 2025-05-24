package chapter_01_getting_started

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
camera := render.Camera {
	type         = .Flying,
	position     = {0, 0, 3},
	direction    = {0, 0, -1},
	up           = {0, 1, 0},
	fov          = linalg.to_radians(f32(45)),
	aspect_ratio = window.aspect_ratio(),
	near         = 0.1,
	far          = 1000,
	speed        = 5,
}

@(private = "file")
container_texture, awesome_texture: render.Texture

@(private = "file")
models := [?]types.TransformMatrix {
	linalg.matrix4_translate_f32({0, 0, 0}),
	linalg.matrix4_translate_f32({2, 5, -15}),
	linalg.matrix4_translate_f32({-1.5, -2.2, -2.5}),
	linalg.matrix4_translate_f32({-3.8, -2, -12.3}),
	linalg.matrix4_translate_f32({2.4, -0.4, -3.5}),
	linalg.matrix4_translate_f32({-1.7, 3.0, -7.5}),
	linalg.matrix4_translate_f32({1.3, -2, -2.5}),
	linalg.matrix4_translate_f32({1.5, 2, -2.5}),
	linalg.matrix4_translate_f32({1.5, 0.2, -1.5}),
	linalg.matrix4_translate_f32({-1.3, 1, -1.5}),
}

exercise_06_04_coordinate_systems_exercise_03 := types.Tableau {
	init = proc() {
		shaders.init_shaders(.TransformDoubleTexture)
		container_texture = render.prepare_texture("textures/container.png", .Diffuse, true)
		awesome_texture = render.prepare_texture("textures/awesomeface.png", .Diffuse, true)
		primitives.cube_send_to_gpu()

		for &model, i in models {
			angle := f32(20 * i)
			model *= linalg.matrix4_rotate_f32(angle, {1, 0.3, 0.5})
		}
	},
	update = proc(delta: f64) {
		camera.aspect_ratio = window.aspect_ratio()

		for &model, i in models {
			if i % 3 != 0 do continue

			model *= linalg.matrix4_rotate_f32(f32(delta), {1, 0.3, 0.5})
		}
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

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)

		gl.Uniform1i(gl.GetUniformLocation(texture_shader, "diffuse_0"), 0)
		gl.Uniform1i(gl.GetUniformLocation(texture_shader, "diffuse_1"), 1)

		for model in models {
			transform := projection * view * model
			gl.UniformMatrix4fv(gl.GetUniformLocation(texture_shader, "transform"), 1, false, raw_data(&transform))

			gl.UseProgram(texture_shader)
			primitives.cube_draw()
		}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
	},
}
