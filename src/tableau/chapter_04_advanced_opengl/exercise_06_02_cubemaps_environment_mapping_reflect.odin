package chapter_04_advanced_opengl

import "../../input"
import "../../parse/obj"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../utils"
import "../../window"
import "core:log"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
initial_camera_position := types.Vec3{1, 0, 5}

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
cubemap: u32

@(private = "file")
backpack_model: render.Scene

exercise_06_02_cubemaps_environment_mapping_reflect :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.SkyboxReflect, .Skybox)

		primitives.cubemap_send_to_gpu()
		cubemap = primitives.cubemap_load_texture("textures/skybox")

		backpack_model =
			obj.load_scene_from_file_obj("models/backpack", "backpack.obj") or_else panic("Failed to load backpack model.")
		render.scene_send_to_gpu(&backpack_model)
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
		mesh_shader := shaders.shaders[.SkyboxReflect]
		skybox_shader := shaders.shaders[.Skybox]

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, cubemap)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view
		model := linalg.identity(types.TransformMatrix)
		transform := pv * model
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

		gl.UseProgram(mesh_shader)

		shaders.set_mat_4x4(mesh_shader, "transform", raw_data(&transform))
		shaders.set_mat_4x4(mesh_shader, "model", raw_data(&model))
		shaders.set_mat_3x3(mesh_shader, "mit", raw_data(&mit))
		shaders.set_vec3(mesh_shader, "view_position", raw_data(&camera.position))

		render.scene_draw(&backpack_model, mesh_shader)

		gl.DepthFunc(gl.LEQUAL)
		gl.UseProgram(skybox_shader)

		cubemap_view := types.TransformMatrix(types.SubTransformMatrix(view))
		cubemap_pv := projection * cubemap_view
		shaders.set_mat_4x4(skybox_shader, "projection_view", raw_data(&cubemap_pv))
		primitives.cubemap_draw(cubemap)

		gl.DepthFunc(gl.LESS)
	},
	teardown = proc() {
		render.scene_clear_from_gpu(&backpack_model)
		render.scene_destroy(&backpack_model)
		primitives.cubemap_clear_from_gpu()
		gl.DeleteTextures(1, &cubemap)
	},
}
