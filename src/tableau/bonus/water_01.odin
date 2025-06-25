package bonus

import "../../input"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
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
initial_camera_position := types.Vec3{0, 0, 3}

@(private = "file")
initial_camera_target := types.Vec3{0, -0.5, 0}

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
water_color := types.Vec3{0, 0, 1}

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
floor_model := linalg.matrix4_translate_f32({0, floor_height + 0.5, 0}) * linalg.matrix4_scale_f32(PLANE_SIZE_SCALE)

@(private = "file")
floor_mit: types.SubTransformMatrix

@(private = "file")
surface_height :: 0

@(private = "file")
surface_model := linalg.matrix4_translate_f32({0, surface_height, 0}) * linalg.matrix4_scale_f32(PLANE_SIZE_SCALE)

@(private = "file")
surface_mit: types.SubTransformMatrix

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
		shaders.set_float(checkerboard_shader, "tile_scale", PLANE_TILE_SCALE)
		shaders.set_float(checkerboard_shader, "shininess", FLOOR_SHININESS)
		render.point_light_set_uniform(&light, checkerboard_shader)

		water_shader := shaders.shaders[.Water]
		gl.UseProgram(water_shader)
		shaders.set_vec3(water_shader, "color", raw_data(&water_color))
		shaders.set_float(water_shader, "shininess", WATER_SHININESS)
		render.point_light_set_uniform(&light, water_shader)

		floor_mit = types.SubTransformMatrix(linalg.inverse_transpose(floor_model))
		surface_mit = types.SubTransformMatrix(linalg.inverse_transpose(surface_model))
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
		checkerboard_shader := shaders.shaders[.Checkerboard2DBlinnPhong]
		water_shader := shaders.shaders[.Water]
		skybox_shader := shaders.shaders[.Skybox]

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		gl.ActiveTexture(gl.TEXTURE0)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		{
			transform := pv * floor_model

			gl.UseProgram(checkerboard_shader)

			shaders.set_vec3(checkerboard_shader, "view_position", raw_data(&camera.position))
			shaders.set_mat_4x4(checkerboard_shader, "model", raw_data(&floor_model))
			shaders.set_mat_3x3(checkerboard_shader, "mit", raw_data(&floor_mit))
			shaders.set_mat_4x4(checkerboard_shader, "transform", raw_data(&transform))


			primitives.plane_draw()
		}

		{
			transform := pv * surface_model

			gl.UseProgram(water_shader)

			shaders.set_vec3(water_shader, "view_position", raw_data(&camera.position))
			shaders.set_mat_4x4(water_shader, "model", raw_data(&surface_model))
			shaders.set_mat_3x3(water_shader, "mit", raw_data(&surface_mit))
			shaders.set_mat_4x4(water_shader, "transform", raw_data(&transform))

			primitives.plane_draw()
		}

		gl.BindTexture(gl.TEXTURE_CUBE_MAP, cubemap)

		gl.DepthFunc(gl.LEQUAL)
		gl.UseProgram(skybox_shader)

		cubemap_view := types.TransformMatrix(types.SubTransformMatrix(view))
		cubemap_pv := projection * cubemap_view
		shaders.set_mat_4x4(skybox_shader, "projection_view", raw_data(&cubemap_pv))
		primitives.cubemap_draw(cubemap)

		gl.DepthFunc(gl.LESS)


	},
	teardown = proc() {
		primitives.plane_clear_from_gpu()
		gl.DeleteTextures(1, &cubemap)
	},
}
