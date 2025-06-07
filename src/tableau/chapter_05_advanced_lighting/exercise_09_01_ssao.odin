package chapter_05_advanced_lighting

import "../../input"
import "../../parse/obj"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
initial_camera_position := types.Vec3{-5, -2, 4}

@(private = "file")
initial_camera_target := types.Vec3{0, -4, 0}

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
backpack_model: render.Scene

@(private = "file")
backpack_transform :=
	linalg.matrix4_translate_f32({0, -4, 0}) *
	linalg.matrix4_rotate_f32(linalg.to_radians(f32(180)), {0, 1, 0}) *
	linalg.matrix4_rotate_f32(linalg.to_radians(f32(-90)), {1, 0, 0})

@(private = "file")
backpack_mit: types.SubTransformMatrix

@(private = "file")
cube_transform := linalg.matrix4_translate_f32({0, 2.5, 0}) * linalg.matrix4_scale_f32(15)

@(private = "file")
cube_mit: types.SubTransformMatrix

@(private = "file")
ambient := types.Vec3{0.5, 0.5, 0.5}

@(private = "file")
diffuse := types.Vec3{1.0, 1.0, 1.0}

@(private = "file")
light := render.PointLight {
	position  = types.Vec3{0, 0, 0},
	ambient   = {1, 1, 1},
	diffuse   = {1, 1, 1},
	specular  = {0, 0, 0},
	constant  = 1,
	linear    = 0.09,
	quadratic = 0.032,
}

exercise_09_01_ssao := types.Tableau {
	init = proc() {
		shaders.init_shaders(.Phong)

		primitives.cube_send_to_gpu()

		backpack_model =
			obj.load_scene_from_file_obj("models/backpack", "backpack.obj") or_else panic("Failed to load backpack model.")
		render.scene_send_to_gpu(&backpack_model)

		backpack_mit =
			types.SubTransformMatrix(linalg.inverse_transpose(backpack_transform)) * linalg.matrix3_scale_f32(-1)
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
		scene_shader := shaders.shaders[.Phong]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)

		gl.UseProgram(scene_shader)
		shaders.set_vec3(scene_shader, "material.ambient", raw_data(&ambient))
		shaders.set_vec3(scene_shader, "material.diffuse", raw_data(&diffuse))
		shaders.set_vec3(scene_shader, "material.specular", raw_data(&diffuse))
		shaders.set_float(scene_shader, "material.shininess", 8.0)

		shaders.set_vec3(scene_shader, "light.position", raw_data(&light.position))
		shaders.set_vec3(scene_shader, "light.ambient", raw_data(&light.ambient))
		shaders.set_vec3(scene_shader, "light.diffuse", raw_data(&light.diffuse))
		shaders.set_vec3(scene_shader, "light.specular", raw_data(&light.specular))

		// Render outside cube
		{
			transform := pv * cube_transform

			shaders.set_mat_4x4(scene_shader, "transform", raw_data(&transform))
			shaders.set_mat_4x4(scene_shader, "model", raw_data(&cube_transform))
			shaders.set_mat_3x3(scene_shader, "mit", raw_data(&cube_mit))

			primitives.cube_draw()
		}

		// Render the backpack
		{
			transform := pv * backpack_transform

			shaders.set_mat_4x4(scene_shader, "transform", raw_data(&transform))
			shaders.set_mat_4x4(scene_shader, "model", raw_data(&backpack_transform))
			shaders.set_mat_3x3(scene_shader, "mit", raw_data(&backpack_mit))

			render.scene_draw(&backpack_model, scene_shader)
		}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		render.scene_clear_from_gpu(&backpack_model)
	},
}
