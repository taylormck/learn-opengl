package chapter_04_advanced_opengl

import "../../input"
import "../../parse/obj"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:log"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{1, 0, 5}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{0, 0, 0}

@(private = "file")
get_initial_camera :: proc() -> render.Camera {
	return {
		type = .Flying,
		position = INITIAL_CAMERA_POSITION,
		direction = INITIAL_CAMERA_TARGET - INITIAL_CAMERA_POSITION,
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
backpack_model: render.Scene

exercise_09_03_geometry_shader_normals :: types.Tableau {
	title = "Normals",
	init = proc() {
		shaders.init_shaders(.TransformTexture, .Normal)
		backpack_model =
			obj.load_scene_from_file_obj("models/backpack", "backpack.obj") or_else panic("Failed to load backpack model.")
		render.scene_send_to_gpu(&backpack_model)
		camera = get_initial_camera()
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
	},
	draw = proc() {
		mesh_shader := shaders.shaders[.TransformTexture]
		normal_shader := shaders.shaders[.Normal]

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)
		defer gl.Enable(gl.DEPTH_TEST)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view
		model := linalg.identity(types.TransformMatrix)
		view_model := view * model
		transform := pv * model
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

		gl.UseProgram(mesh_shader)
		shaders.set_mat_4x4(mesh_shader, "transform", raw_data(&transform))

		render.scene_draw(&backpack_model, mesh_shader)

		// We want to set up some of the textures, but not all of them.
		// Therefore, we use our own custom draw setup here.
		for _, &mesh in backpack_model.meshes {
			texture := mesh.textures[0]
			gl.BindTexture(gl.TEXTURE_2D, texture.id)
			shaders.set_int(mesh_shader, "diffuse_0", 0)
			render.mesh_draw(&mesh, mesh_shader)
		}

		gl.UseProgram(normal_shader)

		shaders.set_mat_4x4(normal_shader, "view_model", raw_data(&view_model))
		shaders.set_mat_4x4(normal_shader, "projection", raw_data(&projection))
		shaders.set_mat_3x3(normal_shader, "mit", raw_data(&mit))

		render.scene_draw(&backpack_model, normal_shader)
	},
	teardown = proc() {
		render.scene_clear_from_gpu(&backpack_model)
		render.scene_destroy(&backpack_model)
	},
}
