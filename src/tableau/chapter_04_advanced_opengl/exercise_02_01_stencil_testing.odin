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

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{5.5, 1, -0.2}

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
marble_texture, metal_texture: render.Texture

exercise_02_01_stencil_testing :: types.Tableau {
	title = "Outline using stencil test",
	init = proc() {
		shaders.init_shaders(.TransformTexture, .SingleColor)
		marble_texture = render.prepare_texture("textures/marble.png", .Diffuse, true)
		metal_texture = render.prepare_texture("textures/metal.png", .Diffuse, true)
		primitives.cube_send_to_gpu()
		camera = get_initial_camera()
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
	},
	draw = proc() {
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT)

		gl.Enable(gl.STENCIL_TEST)
		defer gl.Disable(gl.STENCIL_TEST)
		gl.StencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		gl.ActiveTexture(gl.TEXTURE0)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)

		texture_shader := shaders.shaders[.TransformTexture]
		single_color_shader := shaders.shaders[.SingleColor]

		gl.UseProgram(texture_shader)
		shaders.set_int(texture_shader, "diffuse_0", 0)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		// Draw cubes first
		{
			cube_positions := [?]types.Vec3{{-1, 0, -1}, {2, 0, 0}}

			gl.StencilFunc(gl.ALWAYS, 1, 0xff)
			gl.StencilMask(0xff)

			for position in cube_positions {
				gl.BindTexture(gl.TEXTURE_2D, marble_texture.id)
				model := linalg.matrix4_translate(position)
				transform := pv * model

				shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

				primitives.cube_draw()
			}

			// Now draw the outline
			gl.StencilFunc(gl.NOTEQUAL, 1, 0xff)
			defer gl.StencilFunc(gl.ALWAYS, 1, 0xff)

			gl.StencilMask(0x00)
			defer gl.StencilMask(0xff)

			gl.UseProgram(single_color_shader)
			for position in cube_positions {
				model := linalg.matrix4_translate(position) * linalg.matrix4_scale_f32(1.2)
				transform := pv * model

				shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

				primitives.cube_draw()
			}
		}

		{
			// Draw floor
			gl.UseProgram(texture_shader)
			gl.BindTexture(gl.TEXTURE_2D, metal_texture.id)
			model := linalg.matrix4_translate(types.Vec3{0, -0.5, 0})
			model = model * linalg.matrix4_rotate(linalg.to_radians(f32(-90)), types.Vec3{1, 0, 0})
			model = linalg.matrix4_scale_f32(types.Vec3{10, 1, 10}) * model
			transform := pv * model

			shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

			primitives.quad_draw()
		}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		gl.DeleteTextures(1, &marble_texture.id)
		gl.DeleteTextures(1, &metal_texture.id)
	},
}
