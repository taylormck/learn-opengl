package bonus

import "../../input"
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
background_color := types.Vec3{0, 0, 0}

@(private = "file")
cubemap: u32

@(private = "file")
initial_camera_position := types.Vec3{0, 1, 3}

@(private = "file")
initial_camera_target := types.Vec3{0, -0.5, -3}

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
light := render.PointLight {
	position  = {-10, 10, -50},
	ambient   = {0.2, 0.2, 0.2},
	diffuse   = {0.5, 0.5, 0.5},
	specular  = {1, 1, 1},
	emissive  = {1, 1, 1},
	constant  = 0,
	linear    = 0,
	quadratic = 0,
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
		render.point_light_set_uniform(&light, checkerboard_shader)

		water_shader := shaders.shaders[.Water]
		gl.UseProgram(water_shader)
		shaders.set_vec3(water_shader, "color", raw_data(&water_color))
		shaders.set_float(water_shader, "shininess", WATER_SHININESS)
		shaders.set_int(water_shader, "reflect_map", 0)
		shaders.set_int(water_shader, "refract_map", 1)
		render.point_light_set_uniform(&light, water_shader)

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

	shaders.set_bool(shader, "is_above", is_above)
	shaders.set_vec3(shader, "view_position", raw_data(view_position))
	shaders.set_mat_4x4(shader, "model", raw_data(&surface_model))
	shaders.set_mat_3x3(shader, "mit", raw_data(&surface_mit))
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
