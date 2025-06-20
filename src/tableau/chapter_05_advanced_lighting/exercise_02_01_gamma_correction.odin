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
wood_texture, wood_texture_gamma: render.Texture

@(private = "file")
initial_camera_position := types.Vec3{3, 3, 7}

@(private = "file")
initial_camera_target := types.Vec3{1, -0.5, 2}

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
WHITE :: types.Vec3{1, 1, 1}

@(private = "file")
lights := [?]render.PointLight {
	{
		position = {-3, 0, 0},
		ambient = WHITE * 0.1,
		diffuse = WHITE * 0.25,
		specular = WHITE * 0.25,
		emissive = WHITE,
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {-1, 0, 0},
		ambient = WHITE * 0.2,
		diffuse = WHITE * 0.5,
		specular = WHITE * 0.5,
		emissive = WHITE,
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {1, 0, 0},
		ambient = WHITE * 0.2,
		diffuse = WHITE * 0.75,
		specular = WHITE * 0.75,
		emissive = WHITE,
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {3, 0, 0},
		ambient = WHITE * 0.2,
		diffuse = WHITE,
		specular = WHITE,
		emissive = WHITE,
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
}

@(private = "file")
shininess: f32 = 64

@(private = "file")
plane_material_specular := types.Vec3{0.5, 0.5, 0.5}

@(private = "file")
gamma: bool = true

exercise_02_01_gamma_correction :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.BlinnPhongDiffuseSampledMultilights, .TransformTexture)
		wood_texture = render.prepare_texture("textures/wood.png", .Diffuse, flip_vertically = true)
		wood_texture_gamma = render.prepare_texture(
			"textures/wood.png",
			.Diffuse,
			flip_vertically = true,
			gamma_correction = true,
		)
		primitives.plane_send_to_gpu()

		if gamma do log.info("Enabling gamma correction.")
		else do log.info("Disabling gamma correction")
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

		if .Space in input.input_state.pressed_keys {
			gamma = !gamma

			if gamma do log.info("Enabling gamma correction.")
			else do log.info("Disabling gamma correction")
		}
	},
	draw = proc() {
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		shader := shaders.shaders[.BlinnPhongDiffuseSampledMultilights]
		single_color_shader := shaders.shaders[.TransformTexture]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		model := linalg.identity(types.TransformMatrix)
		transform := projection * view * model
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

		texture := wood_texture_gamma if gamma else wood_texture

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture.id)

		gl.UseProgram(shader)

		shaders.set_int(shader, "num_point_lights", len(lights))
		shaders.set_int(shader, "gamma", i32(gamma))

		shaders.set_vec3(shader, "view_position", raw_data(&camera.position))
		shaders.set_mat_4x4(shader, "transform", raw_data(&transform))
		shaders.set_mat_4x4(shader, "model", raw_data(&model))
		shaders.set_mat_3x3(shader, "mit", raw_data(&mit))

		shaders.set_int(shader, "material.diffuse_0", 0)
		shaders.set_float(shader, "material.shininess", shininess)
		shaders.set_vec3(shader, "material.specular", raw_data(&plane_material_specular))

		for &light, i in lights do render.point_light_array_set_uniform(&light, shader, u32(i))

		primitives.plane_draw()
	},
	teardown = proc() {
		primitives.plane_clear_from_gpu()
		gl.DeleteTextures(1, &wood_texture.id)
		gl.DeleteTextures(1, &wood_texture_gamma.id)
	},
}
