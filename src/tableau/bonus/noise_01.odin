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
import "core:time"
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
app_time: f64 = 0

@(private = "file")
cube_transforms := [?]types.TransformMatrix {
	linalg.matrix4_translate_f32({-1.8, 1, 0}),
	linalg.matrix4_translate_f32({-1.2, 1, 0}),
	linalg.matrix4_translate_f32({-0.6, 1, 0}),
	linalg.matrix4_translate_f32({0, 1, 0}),
	linalg.matrix4_translate_f32({0.6, 1, 0}),
	linalg.matrix4_translate_f32({1.2, 1, 0}),
	linalg.matrix4_translate_f32({1.8, 1, 0}),
	linalg.matrix4_translate_f32({-1.8, 0, 0}),
	linalg.matrix4_translate_f32({-1.2, 0, 0}),
	linalg.matrix4_translate_f32({-0.6, 0, 0}),
	linalg.matrix4_translate_f32({0, 0, 0}),
	linalg.matrix4_translate_f32({0.6, 0, 0}),
	linalg.matrix4_translate_f32({1.2, 0, 0}),
	linalg.matrix4_translate_f32({1.8, 0, 0}),
	linalg.matrix4_translate_f32({-1.8, -1, 0}),
	linalg.matrix4_translate_f32({-1.2, -1, 0}),
	linalg.matrix4_translate_f32({-0.6, -1, 0}),
	linalg.matrix4_translate_f32({0, -1, 0}),
	linalg.matrix4_translate_f32({0.6, -1, 0}),
	linalg.matrix4_translate_f32({1.2, -1, 0}),
	linalg.matrix4_translate_f32({1.8, -1, 0}),
}

@(private = "file")
cube_textures: [len(cube_transforms)]u32

@(private = "file")
custom_color_fns := [?]ColorFn{proc(a: f64) -> [3]u8 {
		return [3]u8{u8(255 * a), u8(min(a * 1.5 - 0.25, 1) * 255), u8(255 * a)}
	}, proc(a: f64) -> [3]u8 {
		return [3]u8{u8(min(a * 1.5 - 0.25, 1) * 255), u8(255 * a), u8(255 * a)}
	}, proc(a: f64) -> [3]u8 {
		return [3]u8{u8(255 * a), u8(255 * a), u8(min(a * 1.5 - 0.25, 1) * 255)}
	}}

noise_01 :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.Texture3D)
		primitives.cube_send_to_gpu()

		gl.GenTextures(len(cube_textures), raw_data(cube_textures[:]))

		// Apple hardware doesn't support the gl_Layer extension.
		when ODIN_OS == .Darwin {
			create_textures_cpu()
		} else {
			create_textures_framebuffer()
		}

		utils.print_gl_errors()
	},
	update = proc(delta: f64) {
		app_time += delta
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
		rotation := linalg.matrix4_rotate_f32(f32(app_time) * f32(linalg.to_radians(50.0)), {0.5, 1, 0})
		scale := linalg.matrix4_scale_f32(0.35)

		gl.ActiveTexture(gl.TEXTURE0)
		shaders.set_int(texture_shader, "diffuse_0", 0)

		for &model, i in cube_transforms {
			gl.BindTexture(gl.TEXTURE_3D, cube_textures[i])

			transform := projection * view * model * rotation * scale
			shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

			z_offset: f32 = f32(app_time) * 0.2 if i >= 18 && i <= 20 else 0
			shaders.set_float(texture_shader, "z_offset", z_offset)

			primitives.cube_draw()
		}
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		gl.DeleteTextures(len(cube_textures), raw_data(cube_textures[:]))
	},
}

create_textures_cpu :: proc() {
	noise_base := noise.generate_noise()
	defer delete(noise_base)

	log.info("Generating stripe texture")
	stripe_data := generate_stripe_data()
	defer delete(stripe_data)
	send_texture_3d_to_gpu(cube_textures[0], stripe_data)

	log.info("Generating checkerboard texture")
	checkerboard_data := generate_checker_board_data()
	defer delete(checkerboard_data)
	send_texture_3d_to_gpu(cube_textures[1], checkerboard_data)

	log.info("Generating noise textures")
	for i in 2 ..= 3 {
		texture_id := cube_textures[i]
		random_data := make([]u8, noise.NOISE_LENGTH * 4)
		defer delete(random_data)

		zoom := int(math.pow(2, f64(i + 1)))
		noise.fill_data_array_bytes(noise_base, random_data, zoom)

		send_texture_3d_to_gpu(texture_id, random_data)
	}

	log.info("Generating smooth noise textures")
	for i in 4 ..= 5 {
		texture_id := cube_textures[i]
		random_data := make([]u8, noise.NOISE_LENGTH * 4)
		defer delete(random_data)

		zoom := math.pow(2, f64(i - 1))
		noise.fill_data_array_bytes_smooth(noise_base, random_data, zoom)

		send_texture_3d_to_gpu(texture_id, random_data)
	}

	log.info("Generating turbulence texture")
	{
		texture_id := cube_textures[6]
		random_data := make([]u8, noise.NOISE_LENGTH * 4)
		defer delete(random_data)

		zoom: f64 = 16
		noise.fill_data_array_bytes_turbulence(noise_base, random_data, zoom)

		send_texture_3d_to_gpu(texture_id, random_data)
	}

	log.info("Generating marble textures")
	for i in 7 ..= 8 {
		texture_id := cube_textures[i]
		j := f64(i - 6)

		zoom: f64 = j * 32
		vein_frequency := math.pow(1.5, j)
		turbulence_power := math.pow(1.5, j)

		marble_data := generate_marble_data(noise_base, vein_frequency, turbulence_power, zoom)

		defer delete(marble_data)

		send_texture_3d_to_gpu(texture_id, marble_data)
	}

	log.info("Generating logistic marble textures")
	for i in 9 ..= 10 {
		texture_id := cube_textures[i]
		j := f64(i - 8)

		zoom: f64 = j * 32
		vein_frequency := math.pow(1.5, j)
		turbulence_power := math.pow(1.5, j)

		marble_data := generate_logistic_marble_data(noise_base, vein_frequency, turbulence_power, zoom)

		defer delete(marble_data)

		send_texture_3d_to_gpu(texture_id, marble_data)
	}

	log.info("Generating colored logistic marble textures")
	for i in 11 ..= 13 {
		texture_id := cube_textures[i]
		j := f64(i - 10)

		zoom: f64 = j * 16
		vein_frequency := math.pow(1.25, j)
		turbulence_power := math.pow(1.5, j)
		color_fn := custom_color_fns[i - 11]

		marble_data := generate_logistic_marble_data(noise_base, vein_frequency, turbulence_power, zoom, color_fn)

		defer delete(marble_data)

		send_texture_3d_to_gpu(texture_id, marble_data)
	}

	log.info("Generating ring texture")
	{
		i := 14
		texture_id := cube_textures[i]

		wood_data := generate_ring_data(ring_density = 20)
		defer delete(wood_data)

		send_texture_3d_to_gpu(texture_id, wood_data)
	}

	log.info("Generating wood textures")
	turbulence_powers := [3]f64{0.05, 0.1, 0.2}
	for i in 15 ..= 17 {
		texture_id := cube_textures[i]

		zoom: f64 = 32
		ring_frequency: f64 = 10
		turbulence_power := turbulence_powers[i - 15]

		wood_data := generate_wood_data(noise_base, ring_frequency, turbulence_power, zoom)

		defer delete(wood_data)

		send_texture_3d_to_gpu(texture_id, wood_data)
	}

	log.info("Generating misty cloud texture")
	{
		i := 18
		texture_id := cube_textures[i]

		cloud_data := generate_misty_cloud_data(noise_base, 32)
		defer delete(cloud_data)

		send_texture_3d_to_gpu(texture_id, cloud_data)
	}

	log.info("Generating quanted cloud texture")
	for i in 19 ..= 20 {
		texture_id := cube_textures[i]

		zoom: f64 = 32 * f64(i - 18)
		cloud_data := generate_cloud_data(noise_base, zoom)
		defer delete(cloud_data)

		send_texture_3d_to_gpu(texture_id, cloud_data)
	}
}

@(private = "file")
send_texture_3d_to_gpu :: proc(texture_id: u32, data: []u8) {
	gl.BindTexture(gl.TEXTURE_3D, texture_id)
	gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)
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

@(private = "file")
ColorFn :: #type proc(a: f64) -> [3]u8

@(private = "file")
default_color_fn :: proc(a: f64) -> [3]u8 {
	value := u8(255 * a)
	return [3]u8{value, value, value}
}

@(private = "file")
generate_marble_data :: proc(
	input_noise: []f64,
	vein_frequency, turbulence_power, max_zoom: f64,
	color_fn: ColorFn = default_color_fn,
) -> []u8 {
	data := make([]u8, noise.NOISE_LENGTH * 4)

	for i in 0 ..< noise.NOISE_WIDTH {
		for j in 0 ..< noise.NOISE_HEIGHT {
			for k in 0 ..< noise.NOISE_DEPTH {
				x := f64(i)
				y := f64(j)
				z := f64(k)

				xyz :=
					x / noise.NOISE_WIDTH +
					y / noise.NOISE_HEIGHT +
					z / noise.NOISE_DEPTH +
					turbulence_power * noise.get_turbulence(input_noise, x, y, z, max_zoom) / 256

				sine_value := math.abs(math.sin(xyz * math.PI * vein_frequency))

				color := color_fn(sine_value)

				index := noise.get_noise_index(i, j, k) * 4
				data[index] = color.r
				data[index + 1] = color.g
				data[index + 2] = color.b
				data[index + 3] = 255
			}
		}
	}

	return data
}

@(private = "file")
generate_logistic_marble_data :: proc(
	input_noise: []f64,
	vein_frequency, turbulence_power, max_zoom: f64,
	color_fn: ColorFn = default_color_fn,
) -> []u8 {
	data := make([]u8, noise.NOISE_LENGTH * 4)

	// A magic function that mostly returns values close to 0 or 1
	logistic :: proc(a: f64) -> f64 {
		return 1.0 / (1.0 + math.pow(2.718, -3 * a))
	}

	for i in 0 ..< noise.NOISE_WIDTH {
		for j in 0 ..< noise.NOISE_HEIGHT {
			for k in 0 ..< noise.NOISE_DEPTH {
				x := f64(i)
				y := f64(j)
				z := f64(k)

				xyz :=
					x / noise.NOISE_WIDTH +
					y / noise.NOISE_HEIGHT +
					z / noise.NOISE_DEPTH +
					turbulence_power * noise.get_turbulence(input_noise, x, y, z, max_zoom) / 256

				sine_value := logistic(math.abs(math.sin(xyz * math.PI * vein_frequency))) * 1.25 - 0.2
				sine_value = clamp(sine_value, -1, 1)
				color := color_fn(sine_value)

				index := noise.get_noise_index(i, j, k) * 4
				data[index] = color.r
				data[index + 1] = color.g
				data[index + 2] = color.b
				data[index + 3] = 255
			}
		}
	}

	return data
}

@(private = "file")
generate_ring_data :: proc(ring_density: f64) -> []u8 {
	data := make([]u8, noise.NOISE_LENGTH * 4)

	for i in 0 ..< noise.NOISE_WIDTH {
		for j in 0 ..< noise.NOISE_HEIGHT {
			for k in 0 ..< noise.NOISE_DEPTH {
				x := (f64(i) - noise.NOISE_WIDTH / 2) / noise.NOISE_WIDTH
				y := (f64(j) - noise.NOISE_WIDTH / 2) / noise.NOISE_WIDTH
				z_dist := math.sqrt(x * x + y * y)

				sine_value := 128 * abs(math.sin(2 * ring_density * z_dist * math.PI))
				sine_floor := math.floor(sine_value)

				red := u8(80 + sine_floor)
				green := u8(30 + sine_floor)

				index := noise.get_noise_index(i, j, k) * 4
				data[index] = red
				data[index + 1] = green
				data[index + 2] = 0
				data[index + 3] = 255
			}
		}
	}

	return data
}

@(private = "file")
generate_wood_data :: proc(input_noise: []f64, ring_frequency, turbulence, max_zoom: f64) -> []u8 {
	data := make([]u8, noise.NOISE_LENGTH * 4)

	for i in 0 ..< noise.NOISE_WIDTH {
		for j in 0 ..< noise.NOISE_HEIGHT {
			for k in 0 ..< noise.NOISE_DEPTH {
				x := (f64(i) - noise.NOISE_WIDTH / 2) / noise.NOISE_WIDTH
				y := (f64(j) - noise.NOISE_WIDTH / 2) / noise.NOISE_WIDTH

				z_offset := turbulence * noise.get_turbulence(input_noise, f64(i), f64(j), f64(k), max_zoom) / 256
				z_dist := math.sqrt(x * x + y * y) + z_offset

				sine_value := 128 * abs(math.sin(2 * ring_frequency * z_dist * math.PI))
				sine_floor := math.floor(sine_value)

				red := u8(80 + sine_floor)
				green := u8(30 + sine_floor)

				index := noise.get_noise_index(i, j, k) * 4
				data[index] = red
				data[index + 1] = green
				data[index + 2] = 0
				data[index + 3] = 255
			}
		}
	}

	return data
}

@(private = "file")
generate_misty_cloud_data :: proc(input_noise: []f64, max_zoom: f64) -> []u8 {
	data := make([]u8, noise.NOISE_LENGTH * 4)

	for i in 0 ..< noise.NOISE_WIDTH {
		for j in 0 ..< noise.NOISE_HEIGHT {
			for k in 0 ..< noise.NOISE_DEPTH {

				brightness := 1 - noise.get_turbulence(input_noise, f64(i), f64(j), f64(k), max_zoom) / 256
				cloud_coverage := u8(brightness * 255)

				index := noise.get_noise_index(i, j, k) * 4
				data[index] = cloud_coverage
				data[index + 1] = cloud_coverage
				data[index + 2] = 255
				data[index + 3] = 255
			}
		}
	}

	return data
}


@(private = "file")
generate_cloud_data :: proc(input_noise: []f64, max_zoom: f64) -> []u8 {
	data := make([]u8, noise.NOISE_LENGTH * 4)

	for i in 0 ..< noise.NOISE_WIDTH {
		for j in 0 ..< noise.NOISE_HEIGHT {
			for k in 0 ..< noise.NOISE_DEPTH {

				brightness := 1 - get_cloud_turbulence(input_noise, f64(i), f64(j), f64(k), max_zoom) / 256
				cloud_coverage := u8(brightness * 255)

				index := noise.get_noise_index(i, j, k) * 4
				data[index] = cloud_coverage
				data[index + 1] = cloud_coverage
				data[index + 2] = 255
				data[index + 3] = 255
			}
		}
	}

	return data
}

@(private = "file")
get_cloud_turbulence :: proc(input_noise: []f64, x, y, z, max_zoom: f64) -> f64 {
	ensure(max_zoom >= 1 && max_zoom <= 64, "provided max_zoom is outside of valid range")

	logistic :: proc(a: f64) -> f64 {
		return 1 / (1 + math.pow(2.718, -0.2 * a))
	}

	cloud_quant :: 130

	zoom := max_zoom

	result: f64 = 0

	for zoom >= 0.9 {
		x_zoom := f64(x) / zoom
		y_zoom := f64(y) / zoom
		z_zoom := f64(z) / zoom

		result += noise.get_smooth_noise(input_noise, zoom, x_zoom, y_zoom, z_zoom) * zoom
		zoom /= 2
	}

	result = 128 * result / max_zoom
	result = 256 * logistic(result - cloud_quant)

	return result
}

@(private = "file")
create_textures_framebuffer :: proc() {
	primitives.full_screen_send_to_gpu()
	defer primitives.full_screen_clear_from_gpu()

	fbo: u32

	gl.GenFramebuffers(1, &fbo)
	defer gl.DeleteFramebuffers(1, &fbo)

	gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)
	defer gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	shaders.init_shaders(.Stripes3D, .Checkerboard3D)

	gl.Viewport(0, 0, noise.NOISE_WIDTH, noise.NOISE_HEIGHT)
	defer gl.Viewport(0, 0, window.width, window.height)

	gl.Disable(gl.DEPTH_TEST)

	{
		log.info("Generating stripes texture")
		shader := shaders.shaders[.Stripes3D]
		gl.UseProgram(shader)

		color_01 := types.Vec3{1, 1, 0}
		color_02 := types.Vec3{0, 0, 1}

		shaders.set_vec3(shader, "color_01", raw_data(&color_01))
		shaders.set_vec3(shader, "color_02", raw_data(&color_02))
		shaders.set_float(shader, "frequency", 20)

		texture_id := cube_textures[0]

		generate_3d_texture(shader, texture_id)

		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	}

	{
		log.info("Generating checkerboard texture")
		shader := shaders.shaders[.Checkerboard3D]
		gl.UseProgram(shader)

		color_01 := types.Vec3{1, 1, 0}
		color_02 := types.Vec3{0, 0, 1}

		shaders.set_vec3(shader, "color_01", raw_data(&color_01))
		shaders.set_vec3(shader, "color_02", raw_data(&color_02))
		shaders.set_float(shader, "frequency", 20)

		texture_id := cube_textures[1]

		generate_3d_texture(shader, texture_id)

		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	}

	noise_texture: u32
	gl.GenTextures(1, &noise_texture)
	defer gl.DeleteTextures(1, &noise_texture)

	{
		log.info("Generating input noise texture")
		shaders.init_shader(.GenNoise3D)
		shader := shaders.shaders[.GenNoise3D]
		gl.UseProgram(shader)
		shaders.set_int(shader, "depth", noise.NOISE_DEPTH)

		current_time := time.time_to_unix(time.now())
		seed := transmute([2]u32)current_time
		shaders.set_uvec2(shader, "seed", raw_data(&seed))

		gl.BindTexture(gl.TEXTURE_3D, noise_texture)

		gl.TexImage3D(
			gl.TEXTURE_3D,
			0,
			gl.RGBA32F,
			noise.NOISE_WIDTH,
			noise.NOISE_HEIGHT,
			noise.NOISE_DEPTH,
			0,
			gl.RGBA,
			gl.FLOAT,
			nil,
		)

		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_R, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_S, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_T, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

		gl.FramebufferTexture(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, noise_texture, 0)
		utils.print_gl_errors()

		log.ensuref(
			gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE,
			"framebuffer error: {}",
			utils.get_framebuffer_status(),
		)

		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		primitives.full_screen_draw_instanced(noise.NOISE_DEPTH)
	}

	log.info("Generating noise textures")
	for i in 2 ..= 3 {
		texture_id := cube_textures[i]
		zoom := math.pow(2, f32(i + 1))

		shaders.init_shader(.Noise3D)
		shader := shaders.shaders[.Noise3D]
		gl.UseProgram(shader)

		shaders.set_float(shader, "zoom", zoom)

		generate_3d_texture(shader, texture_id, noise_texture)
	}

	log.info("Generating smooth noise textures")
	for i in 4 ..= 5 {
		texture_id := cube_textures[i]
		zoom := math.pow(2, f32(i - 1))

		shaders.init_shader(.SmoothNoise3D)
		shader := shaders.shaders[.SmoothNoise3D]
		gl.UseProgram(shader)
		shaders.set_float(shader, "zoom", zoom)

		generate_3d_texture(shader, texture_id, noise_texture)

	}

	log.info("Generating turbulence texture")
	{
		texture_id := cube_textures[6]
		shaders.init_shader(.Turbulence)
		shader := shaders.shaders[.Turbulence]
		gl.UseProgram(shader)

		zoom: f32 = 32
		shaders.set_float(shader, "zoom", zoom)

		generate_3d_texture(shader, texture_id, noise_texture)
	}

	log.info("Generating marble textures")
	for i in 7 ..= 8 {
		texture_id := cube_textures[i]
		j := f32(i - 6)

		shaders.init_shader(.Marble)
		shader := shaders.shaders[.Marble]
		gl.UseProgram(shader)

		zoom: f32 = j * 16
		shaders.set_float(shader, "zoom", zoom)

		vein_frequency := math.pow(1.25, j)
		shaders.set_float(shader, "vein_frequency", vein_frequency)

		turbulence_power := math.pow(1.5, j)
		shaders.set_float(shader, "turbulence_power", turbulence_power)

		generate_3d_texture(shader, texture_id, noise_texture)
	}

	log.info("Generating logistic marble textures")
	for i in 9 ..= 10 {
		texture_id := cube_textures[i]
		j := f32(i - 8)

		shaders.init_shader(.Marble)
		shader := shaders.shaders[.Marble]
		gl.UseProgram(shader)
		shaders.set_bool(shader, "use_logistic", true)

		zoom: f32 = j * 16
		shaders.set_float(shader, "zoom", zoom)

		vein_frequency := math.pow(1.25, j)
		shaders.set_float(shader, "vein_frequency", vein_frequency)

		turbulence_power := math.pow(1.5, j)
		shaders.set_float(shader, "turbulence_power", turbulence_power)

		generate_3d_texture(shader, texture_id, noise_texture)
	}

	log.info("Generating colored logistic marble textures")
	enhance_colors := [3][3]bool{{true, false, false}, {false, true, false}, {false, false, true}}
	for i in 11 ..= 13 {
		texture_id := cube_textures[i]
		j := f32(i - 10)

		shaders.init_shader(.Marble)
		shader := shaders.shaders[.Marble]
		gl.UseProgram(shader)
		shaders.set_bool(shader, "use_logistic", true)
		shaders.set_bvec3(shader, "enhance_colors", enhance_colors[i - 11])

		zoom: f32 = j * 16
		shaders.set_float(shader, "zoom", zoom)

		vein_frequency := math.pow(1.25, j)
		shaders.set_float(shader, "vein_frequency", vein_frequency)

		turbulence_power := math.pow(1.5, j)
		shaders.set_float(shader, "turbulence_power", turbulence_power)

		generate_3d_texture(shader, texture_id, noise_texture)

	}

	log.info("Generating wood textures")
	turbulence_powers := [?]f32{0, 0.05, 0.1, 0.2}
	for i in 14 ..= 17 {
		texture_id := cube_textures[i]

		shaders.init_shader(.Wood)
		shader := shaders.shaders[.Wood]
		gl.UseProgram(shader)

		zoom: f32 = 32
		shaders.set_float(shader, "zoom", zoom)

		ring_frequency: f32 = 10
		shaders.set_float(shader, "ring_frequency", ring_frequency)

		turbulence_power := turbulence_powers[i - 14]
		shaders.set_float(shader, "turbulence_power", turbulence_power)

		generate_3d_texture(shader, texture_id, noise_texture)

	}


	log.info("Generating misty cloud texture")
	{
		i := 18
		texture_id := cube_textures[i]

		shaders.init_shader(.Clouds)
		shader := shaders.shaders[.Clouds]
		gl.UseProgram(shader)
		shaders.set_bool(shader, "use_logistic", false)
		shaders.set_float(shader, "zoom", 32)
		shaders.set_float(shader, "turbulence_power", 1)

		generate_3d_texture(shader, texture_id, noise_texture)
	}

	log.info("Generating quanted cloud texture")
	for i in 19 ..= 20 {
		texture_id := cube_textures[i]

		shaders.init_shader(.Clouds)
		shader := shaders.shaders[.Clouds]
		gl.UseProgram(shader)
		shaders.set_bool(shader, "use_logistic", true)
		shaders.set_float(shader, "quant", 0.5)
		shaders.set_float(shader, "turbulence_power", 1)

		zoom: f32 = 32 * f32(i - 18)
		shaders.set_float(shader, "zoom", zoom)

		generate_3d_texture(shader, texture_id, noise_texture)
	}
}

@(private = "file")
generate_3d_texture :: proc(shader, texture_id: u32, noise_texture: u32 = 0) {
	gl.UseProgram(shader)
	shaders.set_int(shader, "depth", noise.NOISE_DEPTH)

	gl.BindTexture(gl.TEXTURE_3D, texture_id)

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
		nil,
	)

	gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_R, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.FramebufferTexture(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, texture_id, 0)

	log.ensuref(
		gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE,
		"framebuffer error: {}",
		utils.get_framebuffer_status(),
	)

	if noise_texture != 0 {
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_3D, noise_texture)
		shaders.set_int(shader, "noise", 0)
	}

	gl.ClearColor(0, 0, 0, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	primitives.full_screen_draw_instanced(noise.NOISE_DEPTH)

	utils.print_gl_errors()
}
