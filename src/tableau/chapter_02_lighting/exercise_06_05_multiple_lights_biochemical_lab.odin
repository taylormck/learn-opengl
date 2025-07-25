package chapter_02_lighting

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec3{0.9, 0.9, 0.9}

@(private = "file")
container_texture, container_specular_texture: render.Texture

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{2.5, 0, 5}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{0, 0, -2.25}

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
		ambient = {0.04, 0.07, 0.01},
		diffuse = {0.4, 0.7, 0.1},
		specular = {0.4, 0.7, 0.1},
		emissive = {0.4, 0.7, 0.1},
		constant = 1,
		linear = 0.07,
		quadratic = 0.017,
	},
	{
		position = {2.3, -3.3, -4},
		ambient = {0.04, 0.07, 0.01},
		diffuse = {0.4, 0.7, 0.1},
		specular = {0.4, 0.7, 0.1},
		emissive = {0.4, 0.7, 0.1},
		constant = 1,
		linear = 0.07,
		quadratic = 0.017,
	},
	{
		position = {-4, 2, -12},
		ambient = {0.04, 0.07, 0.01},
		diffuse = {0.4, 0.7, 0.1},
		specular = {0.4, 0.7, 0.1},
		emissive = {0.4, 0.7, 0.1},
		constant = 1,
		linear = 0.07,
		quadratic = 0.017,
	},
	{
		position = {0, 0, -3},
		ambient = {0.04, 0.07, 0.01},
		diffuse = {0.4, 0.7, 0.1},
		specular = {0.4, 0.7, 0.1},
		emissive = {0.4, 0.7, 0.1},
		constant = 1,
		linear = 0.07,
		quadratic = 0.017,
	},
}

@(private = "file", rodata)
directional_light := render.DirectionalLight {
	direction = {-0.2, -1, -0.3},
	ambient   = {0.5, 0.5, 0.5},
	diffuse   = {1, 1, 1},
	specular  = {1, 1, 1},
}

@(private = "file")
spot_light := render.SpotLight {
	ambient      = {0, 0, 0},
	diffuse      = {0, 1, 0},
	specular     = {0, 1, 0},
	inner_cutoff = math.cos(linalg.to_radians(f32(7))),
	outer_cutoff = math.cos(linalg.to_radians(f32(10))),
	constant     = 1,
	linear       = 0.07,
	quadratic    = 0.017,
}

@(private = "file", rodata)
obj_material := render.MaterialSampled {
	shininess = 32,
}

@(private = "file")
INITIAL_MODELS := [?]types.TransformMatrix {
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

@(private = "file")
models: [len(INITIAL_MODELS)]types.TransformMatrix

exercise_06_05_multiple_lights_biochemical_lab :: types.Tableau {
	title = "Biochemical lab",
	init = proc() {
		shaders.init_shaders(.Light, .PhongMultiLight)
		container_texture = render.prepare_texture("textures/container2.png", .Diffuse, true)
		container_specular_texture = render.prepare_texture("textures/container2_specular.png", .Specular, true)
		primitives.cube_send_to_gpu()

		models = INITIAL_MODELS
		for &model, i in models {
			angle := f32(20 * i)
			model *= linalg.matrix4_rotate_f32(angle, {1, 0.3, 0.5})
		}

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
		obj_shader := shaders.shaders[.PhongMultiLight]

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

		gl.UseProgram(obj_shader)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)

		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, container_specular_texture.id)

		spot_light.position = camera.position
		spot_light.direction = camera.direction
		render.spot_light_set_uniform(&spot_light, obj_shader)
		render.directional_light_set_uniform(&directional_light, obj_shader)

		shaders.set_int(obj_shader, "num_point_lights", len(point_lights))
		for &point_light, i in point_lights {
			render.point_light_array_set_uniform(&point_light, obj_shader, u32(i))
		}

		render.material_sampled_set_uniform(&obj_material, obj_shader)
		shaders.set_vec3(obj_shader, "view_position", raw_data(&camera.position))

		for &model in models {
			transform := pv * model
			mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
			shaders.set_mat_4x4(obj_shader, "transform", raw_data(&transform))
			shaders.set_mat_4x4(obj_shader, "model", raw_data(&model))
			shaders.set_mat_3x3(obj_shader, "mit", raw_data(&mit))
			primitives.cube_draw()
		}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		gl.DeleteTextures(1, &container_texture.id)
		gl.DeleteTextures(1, &container_specular_texture.id)
	},
}
