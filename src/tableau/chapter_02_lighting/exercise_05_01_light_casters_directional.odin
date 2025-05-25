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
container_texture: render.Texture

@(private = "file")
container_specular_texture: render.Texture

@(private = "file")
initial_camera_position := types.Vec3{5, 6, 1}

@(private = "file")
initial_camera_target := types.Vec3{0, 0, -2}

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
light := render.DirectionalLight {
	ambient   = {0.2, 0.2, 0.2},
	diffuse   = {0.5, 0.5, 0.5},
	specular  = {1, 1, 1},
	direction = {-0.2, -1, -0.3},
}

@(private = "file")
obj_material := render.MaterialSampled {
	shininess = 32,
}

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

exercise_05_01_light_casters_directional := types.Tableau {
	init = proc() {
		shaders.init_shaders(.PhongDirectional)
		container_texture = render.prepare_texture("textures/container2.png", .Diffuse, true)
		container_specular_texture = render.prepare_texture("textures/container2_specular.png", .Specular, true)
		primitives.cube_send_to_gpu()

		for &model, i in models {
			angle := f32(20 * i)
			model *= linalg.matrix4_rotate_f32(angle, {1, 0.3, 0.5})
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
	},
	draw = proc() {
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		obj_shader := shaders.shaders[.PhongDirectional]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.UseProgram(obj_shader)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		defer {
			gl.ActiveTexture(gl.TEXTURE0)
			gl.BindTexture(gl.TEXTURE_2D, 0)
		}

		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, container_specular_texture.id)
		defer {
			gl.ActiveTexture(gl.TEXTURE1)
			gl.BindTexture(gl.TEXTURE_2D, 0)
		}

		render.directional_light_set_uniform(&light, obj_shader)
		render.material_sampled_set_uniform(&obj_material, obj_shader)
		//
		// gl.Uniform1i(gl.GetUniformLocation(obj_shader, "material.diffuse"), 0)
		// gl.Uniform1i(gl.GetUniformLocation(obj_shader, "material.specular"), 1)
		// gl.Uniform1f(gl.GetUniformLocation(obj_shader, "material.shininess"), obj_material.shininess)
		// gl.Uniform3fv(gl.GetUniformLocation(obj_shader, "view_position"), 1, raw_data(&camera.position))

		for &model in models {
			transform := pv * model
			mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
			gl.UniformMatrix4fv(gl.GetUniformLocation(obj_shader, "transform"), 1, false, raw_data(&transform))
			gl.UniformMatrix4fv(gl.GetUniformLocation(obj_shader, "model"), 1, false, raw_data(&model))
			gl.UniformMatrix3fv(gl.GetUniformLocation(obj_shader, "mit"), 1, false, raw_data(&mit))
			primitives.cube_draw()
		}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		gl.DeleteTextures(1, &container_texture.id)
	},
}
