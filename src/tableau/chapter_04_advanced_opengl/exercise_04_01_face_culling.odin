package chapter_04_advanced_opengl

import "../../input"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math"
import "core:math/linalg"
import "core:slice"
import gl "vendor:OpenGL"

@(private = "file")
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
initial_camera_position := types.Vec3{2, 1.5, 3}

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
marble_texture: render.Texture

exercise_04_01_face_culling :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.TransformTexture)
		marble_texture = render.prepare_texture("textures/marble.png", .Diffuse, true)
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
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.CULL_FACE)
		defer gl.Disable(gl.CULL_FACE)

		gl.CullFace(gl.FRONT)
		defer gl.CullFace(gl.BACK)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, marble_texture.id)

		texture_shader := shaders.shaders[.TransformTexture]
		gl.UseProgram(texture_shader)
		shaders.set_int(texture_shader, "diffuse_0", 0)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view
		model := linalg.matrix4_scale_f32(1.75)
		transform := pv * model

		shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

		primitives.cube_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		gl.DeleteTextures(1, &marble_texture.id)
	},
}
