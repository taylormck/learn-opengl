package chapter_05_advanced_lighting

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
brick_wall_texture, brick_wall_normal_texture, brick_wall_displacement_texture: render.Texture

@(private = "file")
initial_camera_position := types.Vec3{-2, 1, 3}

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
light := render.PointLight {
	position  = {0, 0, 1},
	ambient   = {0.2, 0.2, 0.2},
	diffuse   = {0.5, 0.5, 0.5},
	specular  = {1, 1, 1},
	emissive  = {1, 1, 1},
	constant  = 1,
	linear    = 0.09,
	quadratic = 0.032,
}

@(private = "file")
obj_material := render.MaterialSampled {
	shininess = 32,
}

@(private = "file")
obj_specular := types.Vec3{0.5, 0.5, 0.5}

@(private = "file")
wall_model :=
	linalg.matrix4_translate_f32(initial_camera_target) *
	linalg.matrix4_rotate_f32(linalg.to_radians(f32(-45)), types.Vec3{1, 0, 0}) *
	linalg.matrix4_scale_f32(2)

@(private = "file")
wall_mit: types.SubTransformMatrix

@(private = "file")
height_scale: f32 = 0.1

exercise_05_01_parallax_mapping :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.BlinnDisplacement, .Light)
		brick_wall_texture = render.prepare_texture("textures/bricks2.png", .Diffuse, true)
		brick_wall_normal_texture = render.prepare_texture("textures/bricks2_normal.png", .Normal, true)
		brick_wall_displacement_texture = render.prepare_texture("textures/bricks2_disp.png", .Displacement, true)
		primitives.quad_send_to_gpu()
		primitives.cube_send_to_gpu()

		wall_mit = types.SubTransformMatrix(linalg.inverse_transpose(wall_model))
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
		light.position.x = math.sin(f32(time))
		light.position.y = math.cos(f32(time)) * 0.5 + 0.5
		light.position.z = -light.position.y + 1
	},
	draw = proc() {
		gl.ClearColor(0.1, 0.1, 0.1, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		obj_shader := shaders.shaders[.BlinnDisplacement]
		light_shader := shaders.shaders[.Light]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		{
			model := linalg.matrix4_translate(light.position)
			model *= linalg.matrix4_scale_f32(0.2)
			transform := pv * model

			gl.UseProgram(light_shader)

			shaders.set_vec3(light_shader, "light_color", raw_data(&light.emissive))
			shaders.set_mat_4x4(light_shader, "transform", raw_data(&transform))

			primitives.cube_draw()
		}

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, brick_wall_texture.id)

		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, brick_wall_normal_texture.id)

		gl.ActiveTexture(gl.TEXTURE2)
		gl.BindTexture(gl.TEXTURE_2D, brick_wall_displacement_texture.id)

		gl.UseProgram(obj_shader)
		render.point_light_set_uniform(&light, obj_shader)

		shaders.set_int(obj_shader, "material.diffuse_0", 0)
		shaders.set_float(obj_shader, "material.shininess", obj_material.shininess)
		shaders.set_vec3(obj_shader, "material.specular", raw_data(&obj_specular))
		shaders.set_int(obj_shader, "normal_map", 1)
		shaders.set_int(obj_shader, "depth_map", 2)
		shaders.set_float(obj_shader, "height_scale", height_scale)
		shaders.set_vec3(obj_shader, "view_position", raw_data(&camera.position))
		shaders.set_vec3(obj_shader, "light_position", raw_data(&light.position))

		transform := pv * wall_model

		shaders.set_mat_4x4(obj_shader, "transform", raw_data(&transform))
		shaders.set_mat_4x4(obj_shader, "model", raw_data(&wall_model))
		shaders.set_mat_3x3(obj_shader, "mit", raw_data(&wall_mit))

		primitives.quad_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		primitives.quad_clear_from_gpu()
		gl.DeleteTextures(1, &brick_wall_texture.id)
		gl.DeleteTextures(1, &brick_wall_normal_texture.id)
		gl.DeleteTextures(1, &brick_wall_displacement_texture.id)
	},
}
