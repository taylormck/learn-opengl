package bonus

import "../../noise"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../utils"
import "../../window"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
camera := render.Camera {
	type         = .Flying,
	position     = {0, 0, 3},
	direction    = {0, 0, -1},
	up           = {0, 1, 0},
	fov          = linalg.to_radians(f32(45)),
	aspect_ratio = window.aspect_ratio(),
	near         = 0.1,
	far          = 1000,
	speed        = 5,
}

@(private = "file")
time: f64 = 0

@(private = "file")
noise_texture: render.Texture

noise_01 :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.Texture3D)
		primitives.cube_send_to_gpu()

		noise_base := noise.generate_noise()
		defer delete(noise_base)

		random_data := make([]u8, noise.NOISE_LENGTH * 4)
		defer delete(random_data)

		noise.fill_data_array_bytes(noise_base, random_data, zoom = 8)

		noise_texture.type = .Diffuse
		gl.GenTextures(1, &noise_texture.id)
		gl.BindTexture(gl.TEXTURE_3D, noise_texture.id)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

		gl.TexImage3D(
			gl.TEXTURE_3D,
			0,
			gl.RGBA8,
			noise.NOISE_WIDTH,
			noise.NOISE_HEIGHT,
			noise.NOISE_DEPTH,
			0,
			gl.RGBA,
			gl.UNSIGNED_BYTE,
			raw_data(random_data[:]),
		)

		utils.print_gl_errors()
	},
	update = proc(delta: f64) {
		time += delta
		camera.aspect_ratio = window.aspect_ratio()
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		texture_shader := shaders.shaders[.Texture3D]
		gl.UseProgram(texture_shader)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		model := linalg.matrix4_rotate_f32(f32(linalg.to_radians(50.0)), {0.5, 1, 0})
		transform := projection * view * model

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_3D, noise_texture.id)
		shaders.set_int(texture_shader, "diffuse_0", 0)

		// shaders.set_mat_4x4(texture_shader, "model", raw_data(&model))
		shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

		primitives.cube_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		gl.DeleteTextures(1, &noise_texture.id)
	},
}
