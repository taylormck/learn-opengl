package chapter_05_advanced_lighting

import "../../input"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:log"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
background_color := types.Vec3{0, 0, 0}

@(private = "file")
wood_texture: render.Texture

@(private = "file")
initial_camera_position := types.Vec3{0, 0, 3}

@(private = "file")
initial_camera_target := types.Vec3{0, -0.5, 0}

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
	position  = {0, 0, 0},
	ambient   = {0.2, 0.2, 0.2},
	diffuse   = {0.5, 0.5, 0.5},
	specular  = {1, 1, 1},
	emissive  = {1, 1, 1},
	constant  = 1,
	linear    = 0.09,
	quadratic = 0.032,
}

@(private = "file")
phong_shininess: f32 = 8

@(private = "file")
blinn_phong_shininess: f32 = 32

@(private = "file")
plane_material_specular := types.Vec3{0.5, 0.5, 0.5}

@(private = "file")
use_blinn: bool = true

exercise_01_01_advanced_lighting :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.PhongDiffuseSampled, .BlinnPhongDiffuseSampled)
		wood_texture = render.prepare_texture("textures/wood.png", .Diffuse, true)
		primitives.plane_send_to_gpu()

		if use_blinn do log.info("Enabling Blinn-Phong lighting.")
		else do log.info("Disabling Blinn-Phong lighting")
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

		if .B in input.input_state.pressed_keys {
			use_blinn = !use_blinn

			if use_blinn do log.info("Enabling Blinn-Phong lighting.")
			else do log.info("Disabling Blinn-Phong lighting")
		}
	},
	draw = proc() {
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		phong_shader := shaders.shaders[.PhongDiffuseSampled]
		blinn_phong_shader := shaders.shaders[.BlinnPhongDiffuseSampled]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view
		model := linalg.identity(types.TransformMatrix)
		transform := pv * model
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, wood_texture.id)

		shader := blinn_phong_shader if use_blinn else phong_shader
		shininess := blinn_phong_shininess if use_blinn else phong_shininess

		gl.UseProgram(shader)
		shaders.set_vec3(shader, "view_position", raw_data(&camera.position))
		shaders.set_vec3(shader, "light.position", raw_data(&light.position))
		shaders.set_vec3(shader, "light.ambient", raw_data(&light.ambient))
		shaders.set_vec3(shader, "light.diffuse", raw_data(&light.diffuse))
		shaders.set_vec3(shader, "light.specular", raw_data(&light.specular))
		shaders.set_int(shader, "material.diffuse", 0)
		shaders.set_float(shader, "material.shininess", shininess)
		shaders.set_vec3(shader, "material.specular", raw_data(&plane_material_specular))
		shaders.set_mat_4x4(shader, "transform", raw_data(&transform))
		shaders.set_mat_4x4(shader, "model", raw_data(&model))
		shaders.set_mat_3x3(shader, "mit", raw_data(&mit))

		primitives.plane_draw()
	},
	teardown = proc() {
		primitives.plane_clear_from_gpu()
		gl.DeleteTextures(1, &wood_texture.id)
	},
}
