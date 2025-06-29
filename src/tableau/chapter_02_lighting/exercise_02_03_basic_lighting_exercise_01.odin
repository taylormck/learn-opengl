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
time: f64

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{1, 1.5, 4}

@(private = "file")
get_initial_camera :: proc() -> render.Camera {
	return {
		type = .Flying,
		position = INITIAL_CAMERA_POSITION,
		direction = linalg.normalize(-INITIAL_CAMERA_POSITION),
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
INITIAL_LIGHT_POSITION :: types.Vec3{0, 1, 0}

@(private = "file")
light_position: types.Vec3

@(private = "file", rodata)
light_color := types.Vec3{1, 1, 1}

@(private = "file")
CORAL :: types.Vec3{1, 0.5, 0.31}

@(private = "file")
coral_material := render.MaterialCalculated {
	ambient   = CORAL * 0.2,
	diffuse   = CORAL,
	specular  = CORAL,
	shininess = 32,
}

@(private = "file")
cube_position := types.Vec3{0, 0, 0}

exercise_02_03_basic_lighting_exercise_01 :: types.Tableau {
	title = "Specular lighting with moving light",
	init = proc() {
		shaders.init_shaders(.Light, .Phong)
		primitives.cube_send_to_gpu()
		time = 0
		light_position = INITIAL_LIGHT_POSITION
		camera = get_initial_camera()
	},
	update = proc(delta: f64) {
		time += delta
		render.camera_common_update(&camera, delta)

		light_position.x = math.sin(f32(time))
		light_position.z = math.cos(f32(time))
	},
	draw = proc() {
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		light_shader := shaders.shaders[.Light]
		obj_shader := shaders.shaders[.Phong]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		model := linalg.matrix4_translate(light_position)
		model *= linalg.matrix4_scale_f32(0.2)
		transform := pv * model

		gl.UseProgram(light_shader)
		shaders.set_vec3(light_shader, "light_color", raw_data(&light_color))
		shaders.set_mat_4x4(light_shader, "transform", raw_data(&transform))

		primitives.cube_draw()

		model = linalg.matrix4_translate(cube_position)
		transform = pv * model
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

		gl.UseProgram(obj_shader)

		shaders.set_vec3(obj_shader, "light.position", raw_data(&light_position))
		shaders.set_vec3(obj_shader, "light.ambient", raw_data(&light_color))
		shaders.set_vec3(obj_shader, "light.diffuse", raw_data(&light_color))
		shaders.set_vec3(obj_shader, "light.specular", raw_data(&light_color))
		shaders.set_vec3(obj_shader, "material.ambient", raw_data(&coral_material.ambient))
		shaders.set_vec3(obj_shader, "material.diffuse", raw_data(&coral_material.diffuse))
		shaders.set_vec3(obj_shader, "material.specular", raw_data(&coral_material.specular))
		shaders.set_float(obj_shader, "material.shininess", coral_material.shininess)
		shaders.set_vec3(obj_shader, "view_position", raw_data(&camera.position))

		shaders.set_mat_4x4(obj_shader, "transform", raw_data(&transform))
		shaders.set_mat_4x4(obj_shader, "model", raw_data(&model))
		shaders.set_mat_3x3(obj_shader, "mit", raw_data(&mit))

		primitives.cube_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
	},
}
