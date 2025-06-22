package bonus

import "../../noise"
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
camera := render.Camera {
	type         = .Flying,
	position     = {0, 0, 4},
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
cube_transforms := [?]types.TransformMatrix {
	linalg.matrix4_translate_f32({-1.8, 1, 0}),
	linalg.matrix4_translate_f32({-1.2, 1, 0}),
	linalg.matrix4_translate_f32({-0.6, 1, 0}),
	linalg.matrix4_translate_f32({0, 1, 0}),
	linalg.matrix4_translate_f32({0.6, 1, 0}),
	linalg.matrix4_translate_f32({1.2, 1, 0}),
	linalg.matrix4_translate_f32({1.8, 1, 0}),
}

@(private = "file")
cube_textures: [len(cube_transforms)]u32

noise_01 :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.Texture3D)
		primitives.cube_send_to_gpu()

		noise_base := noise.generate_noise()
		defer delete(noise_base)
		gl.GenTextures(len(cube_textures), raw_data(cube_textures[:]))

		stripe_data := generate_stripe_data()
		defer delete(stripe_data)
		send_texture_3d_to_gpu(cube_textures[0], stripe_data)

		checkerboard_data := generate_checker_board_data()
		defer delete(checkerboard_data)
		send_texture_3d_to_gpu(cube_textures[1], checkerboard_data)

		for i in 2 ..= 3 {
			texture_id := cube_textures[i]
			random_data := make([]u8, noise.NOISE_LENGTH * 4)
			defer delete(random_data)

			zoom := int(math.pow(2, f64(i + 1)))
			noise.fill_data_array_bytes(noise_base, random_data, zoom)

			send_texture_3d_to_gpu(texture_id, random_data)
		}

		for i in 4 ..= 5 {
			texture_id := cube_textures[i]
			random_data := make([]u8, noise.NOISE_LENGTH * 4)
			defer delete(random_data)

			zoom := math.pow(2, f64(i - 1))
			noise.fill_data_array_bytes_smooth(noise_base, random_data, zoom)

			send_texture_3d_to_gpu(texture_id, random_data)
		}

		{
			texture_id := cube_textures[6]
			random_data := make([]u8, noise.NOISE_LENGTH * 4)
			defer delete(random_data)

			zoom: f64 = 16
			noise.fill_data_array_bytes_turbulence(noise_base, random_data, zoom)

			send_texture_3d_to_gpu(texture_id, random_data)
		}

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
		rotation := linalg.matrix4_rotate_f32(f32(time) * f32(linalg.to_radians(50.0)), {0.5, 1, 0})
		scale := linalg.matrix4_scale_f32(0.35)

		gl.ActiveTexture(gl.TEXTURE0)
		shaders.set_int(texture_shader, "diffuse_0", 0)

		for &model, i in cube_transforms {
			gl.BindTexture(gl.TEXTURE_3D, cube_textures[i])

			transform := projection * view * model * rotation * scale
			shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

			primitives.cube_draw()
		}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		gl.DeleteTextures(len(cube_textures), raw_data(cube_textures[:]))
	},
}

@(private = "file")
send_texture_3d_to_gpu :: proc(texture_id: u32, data: []u8) {
	gl.BindTexture(gl.TEXTURE_3D, texture_id)
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
		raw_data(data),
	)

	utils.print_gl_errors()
}

@(private = "file")
generate_stripe_data :: proc() -> []u8 {
	data := make([]u8, noise.NOISE_LENGTH * 4)

	for i in 0 ..< noise.NOISE_WIDTH {
		for j in 0 ..< noise.NOISE_HEIGHT {
			for k in 0 ..< noise.NOISE_DEPTH {
				index := noise.get_noise_index(i, j, k) * 4

				if (j / 10) % 2 == 0 {
					// yellow
					data[index] = 255
					data[index + 1] = 255
					data[index + 2] = 0
					data[index + 3] = 255
				} else {
					// blue
					data[index] = 0
					data[index + 1] = 0
					data[index + 2] = 255
					data[index + 3] = 255
				}
			}
		}
	}

	return data
}

@(private = "file")
generate_checker_board_data :: proc() -> []u8 {
	data := make([]u8, noise.NOISE_LENGTH * 4)

	for i in 0 ..< noise.NOISE_WIDTH {
		for j in 0 ..< noise.NOISE_HEIGHT {
			for k in 0 ..< noise.NOISE_DEPTH {
				index := noise.get_noise_index(i, j, k) * 4

				i_step := (i / 10) % 2
				j_step := (j / 10) % 2
				k_step := (k / 10) % 2
				sum_steps := i_step + j_step + k_step

				if sum_steps % 2 == 0 {
					// yellow
					data[index] = 255
					data[index + 1] = 255
					data[index + 2] = 0
					data[index + 3] = 255
				} else {
					// blue
					data[index] = 0
					data[index + 1] = 0
					data[index + 2] = 255
					data[index + 3] = 255
				}
			}
		}
	}

	return data
}
