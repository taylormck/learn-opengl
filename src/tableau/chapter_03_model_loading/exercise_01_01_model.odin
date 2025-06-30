package chapter_03_model_loading

import "../../parse/obj"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{0, 0, 3}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{0, 0, 0}

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

@(private = "file", rodata)
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

@(private = "file", rodata)
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

exercise_01_01_model :: types.Tableau {
	title = "Backpack model",
	init = proc() {
		shaders.init_shaders(.Light, .PhongMultiLight)
		primitives.cube_send_to_gpu()

		backpack_model =
			obj.load_scene_from_file_obj("models/backpack", "backpack.obj") or_else panic("Failed to load backpack model.")

		render.scene_send_to_gpu(&backpack_model)

		camera = get_initial_camera()
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
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

			shaders.set_mat_4x4(light_shader, "transform", raw_data(&transform))
			shaders.set_vec3(light_shader, "light_color", raw_data(&point_light.emissive))
			primitives.cube_draw()
		}

		gl.UseProgram(mesh_shader)

		spot_light.position = camera.position
		spot_light.direction = camera.direction
		render.spot_light_set_uniform(&spot_light, mesh_shader)
		render.directional_light_set_uniform(&directional_light, mesh_shader)

		shaders.set_int(mesh_shader, "num_point_lights", len(point_lights))
		for &point_light, i in point_lights {
			render.point_light_array_set_uniform(&point_light, mesh_shader, u32(i))
		}

		gl.Uniform3fv(gl.GetUniformLocation(mesh_shader, "view_position"), 1, raw_data(&camera.position))

		model := linalg.identity(types.TransformMatrix)
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
		transform := pv * model
		shaders.set_mat_4x4(mesh_shader, "transform", raw_data(&transform))
		shaders.set_mat_4x4(mesh_shader, "model", raw_data(&model))
		shaders.set_mat_3x3(mesh_shader, "mit", raw_data(&mit))

		render.scene_draw_with_materials(&backpack_model, mesh_shader)
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		render.scene_clear_from_gpu(&backpack_model)
		render.scene_destroy(&backpack_model)

	},
}
