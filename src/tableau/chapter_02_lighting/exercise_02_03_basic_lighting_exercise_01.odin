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
time: f64 = 0

@(private = "file")
initial_camera_position := types.Vec3{1, 1.5, 4}

@(private = "file")
camera := render.Camera {
	type         = .Flying,
	position     = initial_camera_position,
	direction    = linalg.normalize(-initial_camera_position),
	up           = {0, 1, 0},
	fov          = linalg.to_radians(f32(45)),
	aspect_ratio = window.aspect_ratio(),
	near         = 0.1,
	far          = 1000,
	speed        = 5,
}

@(private = "file")
light_position := types.Vec3{0, 1, 0}

@(private = "file")
light_color := types.Vec3{1, 1, 1}

@(private = "file")
coral_color :: types.Vec3{1, 0.5, 0.31}

@(private = "file")
coral_material := render.MaterialCalculated {
	ambient   = coral_color * 0.2,
	diffuse   = coral_color,
	specular  = coral_color,
	shininess = 32,
}

@(private = "file")
cube_position := types.Vec3{}

exercise_02_03_basic_lighting_exercise_01 := types.Tableau {
	init = proc() {
		shaders.init_shaders(.Light, .Phong)
		primitives.cube_send_to_gpu()
	},
	update = proc(delta: f64) {
		time += delta

		render.camera_move(&camera, input.input_state.movement, f32(delta))
		render.camera_update_direction(&camera, input.input_state.mouse.offset)
		camera.aspect_ratio = window.aspect_ratio()
		camera.fov = clamp(
			camera.fov - input.input_state.mouse.scroll_offset,
			linalg.to_radians(f32(1)),
			linalg.to_radians(f32(45)),
		)

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
		gl.Uniform3fv(gl.GetUniformLocation(light_shader, "light_color"), 1, raw_data(&light_color))
		gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader, "transform"), 1, false, raw_data(&transform))

		primitives.cube_draw()

		model = linalg.matrix4_translate(cube_position)
		transform = pv * model
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

		gl.UseProgram(obj_shader)
		gl.Uniform3fv(gl.GetUniformLocation(obj_shader, "light.position"), 1, raw_data(&light_position))
		gl.Uniform3fv(gl.GetUniformLocation(obj_shader, "light.ambient"), 1, raw_data(&light_color))
		gl.Uniform3fv(gl.GetUniformLocation(obj_shader, "light.diffuse"), 1, raw_data(&light_color))
		gl.Uniform3fv(gl.GetUniformLocation(obj_shader, "light.specular"), 1, raw_data(&light_color))
		gl.Uniform3fv(gl.GetUniformLocation(obj_shader, "material.ambient"), 1, raw_data(&coral_material.ambient))
		gl.Uniform3fv(gl.GetUniformLocation(obj_shader, "material.diffuse"), 1, raw_data(&coral_material.diffuse))
		gl.Uniform3fv(gl.GetUniformLocation(obj_shader, "material.specular"), 1, raw_data(&coral_material.specular))
		gl.Uniform1f(gl.GetUniformLocation(obj_shader, "material.shininess"), coral_material.shininess)
		gl.Uniform3fv(gl.GetUniformLocation(obj_shader, "view_position"), 1, raw_data(&camera.position))
		gl.UniformMatrix4fv(gl.GetUniformLocation(obj_shader, "transform"), 1, false, raw_data(&transform))
		gl.UniformMatrix4fv(gl.GetUniformLocation(obj_shader, "model"), 1, false, raw_data(&model))
		gl.UniformMatrix3fv(gl.GetUniformLocation(obj_shader, "mit"), 1, false, raw_data(&mit))
		primitives.cube_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
	},
}
