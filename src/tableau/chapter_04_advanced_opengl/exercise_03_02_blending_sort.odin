package chapter_04_advanced_opengl

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math/linalg"
import "core:slice"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{0, 0, 3}

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
marble_texture, metal_texture, window_texture: render.Texture

@(private = "file", rodata)
cube_positions := [?]types.Vec3{{-1, 0, -1}, {2, 0, 0}}

@(private = "file")
WINDOW_POSITIONS :: [?]types.Vec3{{-1, 0, -0.48}, {2, 0, 0.51}, {0.5, 0, 0.7}, {0.2, 0, -2.3}, {1, 0, -0.6}}

exercise_03_02_blending_sort :: types.Tableau {
	title = "Blending alpha",
	init = proc() {
		shaders.init_shaders(.TransformTexture)
		marble_texture = render.prepare_texture("textures/marble.png", .Diffuse, true)
		metal_texture = render.prepare_texture("textures/metal.png", .Diffuse, true)
		window_texture = render.prepare_texture("textures/blending_transparent_window.png", .Diffuse, true)

		gl.BindTexture(gl.TEXTURE_2D, window_texture.id)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

		primitives.cube_send_to_gpu()

		camera = get_initial_camera()
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
	},
	draw = proc() {
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		gl.ActiveTexture(gl.TEXTURE0)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)

		texture_shader := shaders.shaders[.TransformTexture]
		gl.UseProgram(texture_shader)
		shaders.set_int(texture_shader, "diffuse_0", 0)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		// Draw cubes first
		{
			gl.BindTexture(gl.TEXTURE_2D, marble_texture.id)
			for position in cube_positions {
				model := linalg.matrix4_translate(position)
				transform := pv * model

				shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

				primitives.cube_draw()
			}
		}

		{
			// Draw floor
			gl.BindTexture(gl.TEXTURE_2D, metal_texture.id)
			model := linalg.matrix4_translate(types.Vec3{0, -0.5, 0})
			model = model * linalg.matrix4_rotate(linalg.to_radians(f32(-90)), types.Vec3{1, 0, 0})
			model = linalg.matrix4_scale_f32(types.Vec3{10, 1, 10}) * model
			transform := pv * model

			shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

			primitives.quad_draw()
		}

		// Draw windows last
		{
			gl.Enable(gl.BLEND)
			defer gl.Disable(gl.BLEND)

			gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
			gl.BindTexture(gl.TEXTURE_2D, window_texture.id)

			// Create a local copy of the immutable global
			window_positions := WINDOW_POSITIONS

			slice.sort_by(window_positions[:], distance_order)

			for position in window_positions {
				model := linalg.matrix4_translate(position)
				transform := pv * model

				shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

				primitives.quad_draw()
			}
		}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		gl.DeleteTextures(1, &marble_texture.id)
		gl.DeleteTextures(1, &metal_texture.id)
		gl.DeleteTextures(1, &window_texture.id)
	},
}

distance_squared_from_camera :: proc(v: types.Vec3) -> f32 {
	diff := camera.position - v
	return linalg.dot(diff, diff)
}

distance_order :: proc(lhs, rhs: types.Vec3) -> bool {
	return distance_squared_from_camera(lhs) > distance_squared_from_camera(rhs)
}
