package chapter_03_model_loading

import "../../input"
import "../../parse/obj"
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
initial_camera_position := types.Vec3{0, 0, 3}

@(private = "file")
initial_camera_target := types.Vec3{0, 0, 0}

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
point_lights := [?]render.PointLight {
	{
		position = {0.4, 0.2, 2},
		ambient = {0.2, 0.2, 0.2},
		diffuse = {0.5, 0.5, 0.5},
		emissive = {1, 1, 1},
		specular = {1, 1, 1},
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {2.3, -3.3, -4},
		ambient = {0.2, 0.2, 0.2},
		diffuse = {1, 0, 0},
		emissive = {1, 0, 0},
		specular = {1, 1, 1},
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {-4, 2, -12},
		ambient = {0.2, 0.2, 0.2},
		diffuse = {0, 1, 0},
		emissive = {0, 1, 0},
		specular = {1, 1, 1},
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {0, 0, -3},
		ambient = {0.2, 0.2, 0.2},
		diffuse = {0, 0, 1},
		emissive = {0, 0, 1},
		specular = {1, 1, 1},
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
}

@(private = "file")
directional_light := render.DirectionalLight {
	direction = {-0.2, -1, -0.3},
	ambient   = {0.2, 0.2, 0.2},
	diffuse   = {0.5, 0.5, 0.5},
	specular  = {1, 1, 1},
}

@(private = "file")
spot_light := render.SpotLight {
	ambient      = {0.2, 0.2, 0.2},
	diffuse      = {0.5, 0.5, 0.5},
	specular     = {1, 1, 1},
	inner_cutoff = math.cos(linalg.to_radians(f32(12.5))),
	outer_cutoff = math.cos(linalg.to_radians(f32(17.5))),
	constant     = 1,
	linear       = 0.09,
	quadratic    = 0.032,
}

@(private = "file")
backpack_model: render.Scene

exercise_01_01_model := types.Tableau {
	init = proc() {
		shaders.init_shaders(.Light, .PhongMultiLight)

		backpack_model =
			obj.load_scene_from_file_obj("models/backpack", "backpack.obj") or_else panic("Failed to load backpack model.")
		render.scene_send_to_gpu(&backpack_model)

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
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		light_shader := shaders.shaders[.Light]
		mesh_shader := shaders.shaders[.PhongMultiLight]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.UseProgram(light_shader)
		for &point_light in point_lights {
			model := linalg.matrix4_translate(point_light.position)
			model *= linalg.matrix4_scale_f32({0.2, 0.2, 0.2})
			transform := pv * model

			gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader, "transform"), 1, false, raw_data(&transform))
			gl.Uniform3fv(gl.GetUniformLocation(light_shader, "light_color"), 1, raw_data(&point_light.emissive))
			primitives.cube_draw()
		}

		gl.UseProgram(mesh_shader)

		spot_light.position = camera.position
		spot_light.direction = camera.direction
		render.spot_light_set_uniform(&spot_light, mesh_shader)
		render.directional_light_set_uniform(&directional_light, mesh_shader)

		gl.Uniform1i(gl.GetUniformLocation(mesh_shader, "num_point_lights"), len(point_lights))
		for &point_light, i in point_lights {
			render.point_light_array_set_uniform(&point_light, mesh_shader, u32(i))
		}

		gl.Uniform3fv(gl.GetUniformLocation(mesh_shader, "view_position"), 1, raw_data(&camera.position))

		model := linalg.identity(types.TransformMatrix)
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
		transform := pv * model
		gl.UniformMatrix4fv(gl.GetUniformLocation(mesh_shader, "transform"), 1, false, raw_data(&transform))
		gl.UniformMatrix4fv(gl.GetUniformLocation(mesh_shader, "model"), 1, false, raw_data(&model))
		gl.UniformMatrix3fv(gl.GetUniformLocation(mesh_shader, "mit"), 1, false, raw_data(&mit))

		render.scene_draw(&backpack_model, mesh_shader)
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		render.scene_clear_from_gpu(&backpack_model)
		render.scene_destroy(&backpack_model)
	},
}
