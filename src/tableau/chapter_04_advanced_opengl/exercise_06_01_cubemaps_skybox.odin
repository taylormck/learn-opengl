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
INITIAL_CAMERA_POSITION :: types.Vec3{4.5, 0.6, -0.3}

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
container_texture: render.Texture

@(private = "file")
cubemap: u32

exercise_06_01_cubemaps_skybox :: types.Tableau {
	title = "Skybox",
	init = proc() {
		shaders.init_shaders(.TransformTexture, .Skybox)
		container_texture = render.prepare_texture("textures/container.png", .Diffuse, true)

		primitives.cubemap_send_to_gpu()
		primitives.cube_send_to_gpu()

		cubemap = primitives.cubemap_load_texture("textures/skybox")

		camera = get_initial_camera()
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
	},
	draw = proc() {
		texture_shader := shaders.shaders[.TransformTexture]
		skybox_shader := shaders.shaders[.Skybox]

		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view
		model := linalg.identity(types.TransformMatrix)
		transform := pv * model
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

		gl.UseProgram(texture_shader)
		gl.ActiveTexture(gl.TEXTURE0)
		shaders.set_int(texture_shader, "diffuse_0", 0)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		shaders.set_mat_4x4(texture_shader, "transform", raw_data(&transform))

		primitives.cube_draw()

		gl.DepthFunc(gl.LEQUAL)
		gl.UseProgram(skybox_shader)
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, cubemap)

		cubemap_view := types.TransformMatrix(types.SubTransformMatrix(view))
		cubemap_pv := projection * cubemap_view
		shaders.set_mat_4x4(skybox_shader, "projection_view", raw_data(&cubemap_pv))
		primitives.cubemap_draw(cubemap)

		gl.DepthFunc(gl.LESS)
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		primitives.cubemap_clear_from_gpu()
		gl.DeleteTextures(1, &container_texture.id)
		gl.DeleteTextures(1, &cubemap)
	},
}
