package chapter_04_advanced_opengl

import "../../input"
import "../../parse/obj"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import gl "vendor:OpenGL"

@(private = "file")
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
initial_camera_position := types.Vec3{0, 3, 55}

@(private = "file")
initial_camera_target := types.Vec3{-15, 0, 0}

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
NUM_ASTEROIDS :: 100000

@(private = "file")
asteroid_model_transforms: [dynamic]types.TransformMatrix

@(private = "file")
planet_model: render.Scene

@(private = "file")
asteroid_model: render.Scene

@(private = "file")
light := render.DirectionalLight {
	ambient   = {0.2, 0.2, 0.2},
	diffuse   = {0.5, 0.5, 0.5},
	specular  = {1, 1, 1},
	direction = {-0.2, -1, -0.3},
}

exercise_10_02_asteroids := types.Tableau {
	init = proc() {
		shaders.init_shaders(.Planet)

		planet_model =
			obj.load_scene_from_file_obj("models/planet", "planet.obj") or_else panic("Failed to load planet model.")
		render.scene_send_to_gpu(&planet_model)

		asteroid_model =
			obj.load_scene_from_file_obj("models/rock", "rock.obj") or_else panic("Failed to load rock model.")
		render.scene_send_to_gpu(&asteroid_model)

		asteroid_model_transforms = make([dynamic]types.TransformMatrix, NUM_ASTEROIDS)
		set_asteroid_transforms()

		// for &mesh in asteroid_model.meshes do render.mesh_send_transforms_to_gpu(&mesh, asteroid_model_transforms[:])
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

		planet_shader := shaders.shaders[.Planet]
		asteroid_shader := shaders.shaders[.Planet]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		gl.UseProgram(planet_shader)
		render.directional_light_set_uniform(&light, planet_shader)
		gl.Uniform3fv(gl.GetUniformLocation(planet_shader, "view_position"), 1, raw_data(&camera.position))

		{
			model := linalg.matrix4_scale_f32(types.Vec3{4, 4, 4})
			mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
			transform := pv * model

			gl.UniformMatrix4fv(gl.GetUniformLocation(planet_shader, "transform"), 1, false, raw_data(&transform))
			gl.UniformMatrix4fv(gl.GetUniformLocation(planet_shader, "model"), 1, false, raw_data(&model))
			gl.UniformMatrix3fv(gl.GetUniformLocation(planet_shader, "mit"), 1, false, raw_data(&mit))

			render.scene_draw(&planet_model, planet_shader)
		}

		for &model in asteroid_model_transforms {
			mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
			transform := pv * model

			gl.UniformMatrix4fv(gl.GetUniformLocation(planet_shader, "transform"), 1, false, raw_data(&transform))
			gl.UniformMatrix4fv(gl.GetUniformLocation(planet_shader, "model"), 1, false, raw_data(&model))
			gl.UniformMatrix3fv(gl.GetUniformLocation(planet_shader, "mit"), 1, false, raw_data(&mit))

			render.scene_draw(&asteroid_model, planet_shader)
		}

	},
	teardown = proc() {
		render.scene_clear_from_gpu(&planet_model)
		render.scene_destroy(&planet_model)

		render.scene_clear_from_gpu(&asteroid_model)
		render.scene_destroy(&asteroid_model)

		delete(asteroid_model_transforms)
	},
}

set_asteroid_transforms :: proc() {
	radius :: 50
	rotation_axis :: types.Vec3{0.4, 0.6, 0.8}
	scale_multiple: f32 : 1.0 / 10

	for i in 0 ..< NUM_ASTEROIDS {
		angle := f32(i) / f32(NUM_ASTEROIDS) * math.TAU

		translation := types.Vec3 {
			math.sin(angle) * radius + generate_random_displacement(),
			generate_random_displacement() * 0.1,
			math.cos(angle) * radius + generate_random_displacement(),
		}

		scale := rand.float32_exponential(10) * scale_multiple + 0.005
		rotation := rand.float32() * math.TAU

		asteroid_model_transforms[i] =
			linalg.matrix4_translate(translation) *
			linalg.matrix4_rotate(rotation, rotation_axis) *
			linalg.matrix4_scale_f32(scale)
	}
}

generate_random_displacement :: proc() -> f32 {
	offset :: 10.0

	return rand.float32_normal(offset, 5.0) - offset
}
