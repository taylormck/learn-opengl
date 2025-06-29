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

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{2, 1.5, 3}

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
marble_texture: render.Texture

exercise_04_01_face_culling :: types.Tableau {
	title = "Face culling",
	init = proc() {
		shaders.init_shaders(.TransformTexture)
		marble_texture = render.prepare_texture("textures/marble.png", .Diffuse, true)
		primitives.cube_send_to_gpu()
		camera = get_initial_camera()
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
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
