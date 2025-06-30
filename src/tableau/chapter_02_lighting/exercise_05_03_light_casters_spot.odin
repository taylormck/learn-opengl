package chapter_02_lighting

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
container_texture, container_specular_texture: render.Texture

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

@(private = "file")
light := render.SpotLight {
	ambient      = {0.2, 0.2, 0.2},
	diffuse      = {0.5, 0.5, 0.5},
	specular     = {1, 1, 1},
	outer_cutoff = f32(math.cos(linalg.to_radians(12.5))),
	inner_cutoff = f32(math.cos(linalg.to_radians(12.5))),
	constant     = 1,
	linear       = 0.09,
	quadratic    = 0.032,
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

exercise_05_03_light_casters_spot :: types.Tableau {
	title = "Spot light",
	init = proc() {
		shaders.init_shaders(.PhongSpotLight)
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
		gl.ClearColor(0.1, 0.1, 0.1, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		obj_shader := shaders.shaders[.PhongSpotLight]

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

		light.position = camera.position
		light.direction = camera.direction
		render.spot_light_set_uniform(&light, obj_shader)
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
