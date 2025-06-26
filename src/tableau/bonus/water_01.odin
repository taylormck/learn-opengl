package bonus

import "../../input"
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
background_color := types.Vec3{0, 0, 0}

@(private = "file")
cubemap: u32

@(private = "file")
initial_camera_position := types.Vec3{0, 0.5, 3}

@(private = "file")
initial_camera_target := types.Vec3{0, -0.5, -5}

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
light := render.DirectionalLight {
	direction = {1, -1, 5},
	ambient   = {0.2, 0.2, 0.2},
	diffuse   = {0.5, 0.5, 0.5},
	specular  = {1, 1, 1},
}

@(private = "file")
tile_color_01 := types.Vec3{1, 1, 1}

@(private = "file")
tile_color_02 := types.Vec3{0, 0, 0}

@(private = "file")
water_color := types.Vec3{0, 0.25, 1}

@(private = "file")
WATER_SHININESS :: 64

@(private = "file")
FLOOR_SHININESS :: 8

@(private = "file")
PLANE_SIZE_SCALE :: 128.0 / 25.0

@(private = "file")
PLANE_TILE_SCALE :: PLANE_SIZE_SCALE / 2

@(private = "file")
floor_height :: -10

@(private = "file")
floor_model :=
	linalg.matrix4_translate_f32({0, floor_height + 0.5, 0}) *
	linalg.matrix4_scale_f32({PLANE_SIZE_SCALE, 1, PLANE_SIZE_SCALE})

@(private = "file")
floor_mit: types.SubTransformMatrix

@(private = "file")
SURFACE_HEIGHT :: 0

@(private = "file")
surface_model :=
	linalg.matrix4_translate_f32({0, SURFACE_HEIGHT + 0.5, 0}) *
	linalg.matrix4_scale_f32({PLANE_SIZE_SCALE, 1, PLANE_SIZE_SCALE})

@(private = "file")
surface_mit: types.SubTransformMatrix

@(private = "file")
reflect_fbo, reflect_texture, refract_fbo, refract_texture: u32

@(private = "file")
turbulence_texture: u32

@(private = "file")
app_time: f64

water_01 :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.Checkerboard2DBlinnPhong, .Skybox, .Water)
		primitives.plane_send_to_gpu()
		primitives.cubemap_send_to_gpu()

		cubemap = primitives.cubemap_load_texture("textures/skybox")

		checkerboard_shader := shaders.shaders[.Checkerboard2DBlinnPhong]
		gl.UseProgram(checkerboard_shader)
		shaders.set_vec3(checkerboard_shader, "color_01", raw_data(&tile_color_01))
		shaders.set_vec3(checkerboard_shader, "color_02", raw_data(&tile_color_02))
		shaders.set_vec3(checkerboard_shader, "color_03", raw_data(&water_color))
		shaders.set_float(checkerboard_shader, "tile_scale", PLANE_TILE_SCALE)
		shaders.set_float(checkerboard_shader, "shininess", FLOOR_SHININESS)
		render.directional_light_set_uniform(&light, checkerboard_shader)

		generate_turbulence_texture()

		water_shader := shaders.shaders[.Water]
		gl.UseProgram(water_shader)
		shaders.set_vec3(water_shader, "color", raw_data(&water_color))
		shaders.set_float(water_shader, "shininess", WATER_SHININESS)
		shaders.set_int(water_shader, "reflect_map", 0)
		shaders.set_int(water_shader, "refract_map", 1)
		shaders.set_int(water_shader, "noise", 2)
		render.directional_light_set_uniform(&light, water_shader)

		floor_mit = types.SubTransformMatrix(linalg.inverse_transpose(floor_model))
		surface_mit = types.SubTransformMatrix(linalg.inverse_transpose(surface_model))

		init_buffer(&reflect_fbo, &reflect_texture)
		init_buffer(&refract_fbo, &refract_texture)
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
		app_time += delta
	},
	draw = proc() {
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		is_above := camera.position.y > SURFACE_HEIGHT

		if is_above {
			gl.BindFramebuffer(gl.FRAMEBUFFER, refract_fbo)
			draw_floor(is_above, &pv, &camera.position)

			reflect_camera := get_reflect_camera()

			reflect_projection := render.camera_get_projection(&reflect_camera)
			reflect_view := render.camera_get_view(&reflect_camera)

			gl.BindFramebuffer(gl.FRAMEBUFFER, reflect_fbo)
			draw_skybox(&reflect_projection, &reflect_view)
		} else {
			gl.BindFramebuffer(gl.FRAMEBUFFER, refract_fbo)
			draw_skybox(&projection, &view)
		}

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, reflect_texture)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, refract_texture)
		gl.ActiveTexture(gl.TEXTURE2)
		gl.BindTexture(gl.TEXTURE_3D, turbulence_texture)

		draw_surface(is_above, &pv, &camera.position)
		draw_floor(is_above, &pv, &camera.position)

		if is_above do draw_skybox(&projection, &view)
	},
	teardown = proc() {
		primitives.plane_clear_from_gpu()
		gl.DeleteTextures(1, &cubemap)

		gl.DeleteFramebuffers(1, &reflect_fbo)
		gl.DeleteTextures(1, &reflect_texture)

		gl.DeleteFramebuffers(1, &refract_fbo)
		gl.DeleteTextures(1, &refract_texture)

		gl.DeleteTextures(1, &turbulence_texture)
	},
	framebuffer_size_callback = proc() {
		gl.BindTexture(gl.TEXTURE_2D, reflect_texture)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, window.width, window.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)

		gl.BindTexture(gl.TEXTURE_2D, refract_texture)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, window.width, window.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)
	},
}

@(private = "file")
draw_floor :: proc(is_above: bool, projection_view: ^types.TransformMatrix, view_position: ^types.Vec3) {
	shader := shaders.shaders[.Checkerboard2DBlinnPhong]
	transform := projection_view^ * floor_model

	gl.UseProgram(shader)

	shaders.set_vec3(shader, "view_position", raw_data(view_position))
	shaders.set_mat_4x4(shader, "model", raw_data(&floor_model))
	shaders.set_mat_3x3(shader, "mit", raw_data(&floor_mit))
	shaders.set_mat_4x4(shader, "transform", raw_data(&transform))

	primitives.plane_draw()
}

@(private = "file")
draw_surface :: proc(is_above: bool, projection_view: ^types.TransformMatrix, view_position: ^types.Vec3) {
	shader := shaders.shaders[.Water]
	transform := projection_view^ * surface_model

	gl.UseProgram(shader)

	shaders.set_float(shader, "noise_offset", f32(app_time * 0.2))
	shaders.set_bool(shader, "is_above", is_above)
	shaders.set_vec3(shader, "view_position", raw_data(view_position))
	shaders.set_mat_4x4(shader, "model", raw_data(&surface_model))
	// shaders.set_mat_3x3(shader, "mit", raw_data(&surface_mit))
	shaders.set_mat_4x4(shader, "transform", raw_data(&transform))

	primitives.plane_draw()
}

@(private = "file")
draw_skybox :: proc(projection, view: ^types.TransformMatrix) {
	shader := shaders.shaders[.Skybox]

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_CUBE_MAP, cubemap)

	gl.DepthFunc(gl.LEQUAL)
	defer gl.DepthFunc(gl.LESS)

	gl.UseProgram(shader)

	cubemap_view := types.TransformMatrix(types.SubTransformMatrix(view^))
	cubemap_pv := projection^ * cubemap_view
	shaders.set_mat_4x4(shader, "projection_view", raw_data(&cubemap_pv))
	primitives.cubemap_draw(cubemap)
}

@(private = "file")
init_buffer :: proc(fbo, texture_id: ^u32) {
	gl.GenFramebuffers(1, fbo)
	gl.BindFramebuffer(gl.FRAMEBUFFER, fbo^)

	gl.GenTextures(1, texture_id)
	gl.BindTexture(gl.TEXTURE_2D, texture_id^)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, window.width, window.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture_id^, 0)

	log.ensuref(
		gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE,
		"framebuffer error: {}",
		utils.get_framebuffer_status(),
	)
}

@(private = "file")
get_reflect_camera :: proc() -> (reflect_camera: render.Camera) {
	reflect_camera = camera

	// reflect_camera.position.y += SURFACE_HEIGHT
	reflect_camera.position.y *= -1
	// reflect_camera.position.y -= SURFACE_HEIGHT

	reflect_camera.direction.y *= -1

	return reflect_camera
}

@(private = "file")
generate_turbulence_texture :: proc() {
	primitives.full_screen_send_to_gpu()
	defer primitives.full_screen_clear_from_gpu()

	fbo: u32

	gl.GenFramebuffers(1, &fbo)
	defer gl.DeleteFramebuffers(1, &fbo)

	gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)
	defer gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	gl.Viewport(0, 0, noise.NOISE_WIDTH, noise.NOISE_HEIGHT)
	defer gl.Viewport(0, 0, window.width, window.height)

	gl.Disable(gl.DEPTH_TEST)

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

	log.info("Generating turbulence texture")
	{
		gl.GenTextures(1, &turbulence_texture)
		shaders.init_shader(.TurbulenceSine)
		shader := shaders.shaders[.TurbulenceSine]
		gl.UseProgram(shader)

		zoom: f32 = 64
		shaders.set_float(shader, "zoom", zoom)

		generate_3d_texture(shader, turbulence_texture, noise_texture)
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
