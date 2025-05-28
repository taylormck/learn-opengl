package chapter_04_advanced_opengl

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
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
initial_camera_position := types.Vec3{4.5, 0.6, -0.3}

@(private = "file")
initial_camera_target := types.Vec3{0, 0, 0}

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
container_texture: render.Texture

@(private = "file")
cubemap: primitives.Cubemap

exercise_06_01_cubemaps_skybox := types.Tableau {
	init = proc() {
		shaders.init_shaders(.TransformTexture, .Skybox)
		container_texture = render.prepare_texture("textures/container.png", .Diffuse, true)
		cubemap = primitives.cubemap_load("textures/skybox")
		primitives.cube_send_to_gpu()
	},
	update = proc(delta: f64) {
		camera.aspect_ratio = window.aspect_ratio()

		render.camera_move(&camera, input.input_state.movement, f32(delta))
		render.camera_update_direction(&camera, input.input_state.mouse.offset)
		camera.fov = clamp(
			camera.fov - input.input_state.mouse.scroll_offset,
			linalg.to_radians(f32(1)),
			linalg.to_radians(f32(45)),
		)
	},
	draw = proc() {
		texture_shader := shaders.shaders[.TransformTexture]
		skybox_shader := shaders.shaders[.Skybox]

		gl.ActiveTexture(gl.TEXTURE0)
		gl.Uniform1i(gl.GetUniformLocation(texture_shader, "diffuse_0"), 0)
		gl.UseProgram(texture_shader)

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, cubemap.texture_id)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view
		model := linalg.identity(types.TransformMatrix)
		transform := pv * model
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		gl.UniformMatrix4fv(gl.GetUniformLocation(texture_shader, "transform"), 1, false, raw_data(&transform))
		gl.UniformMatrix4fv(gl.GetUniformLocation(texture_shader, "model"), 1, false, raw_data(&model))
		gl.UniformMatrix3fv(gl.GetUniformLocation(texture_shader, "mit"), 1, false, raw_data(&mit))

		primitives.cube_draw()

		gl.DepthFunc(gl.LEQUAL)
		gl.UseProgram(skybox_shader)

		cubemap_view := types.TransformMatrix(types.SubTransformMatrix(view))
		cubemap_pv := projection * cubemap_view
		gl.UniformMatrix4fv(gl.GetUniformLocation(skybox_shader, "projection_view"), 1, false, raw_data(&cubemap_pv))
		primitives.cubemap_draw(&cubemap)

		gl.DepthFunc(gl.LESS)

	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		primitives.cubemap_free(&cubemap)
		gl.DeleteTextures(1, &container_texture.id)
	},
}
