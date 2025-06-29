package chapter_02_lighting

import "../../input"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
container_texture: render.Texture

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{-2, -1, 3}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{0.45, 0.45, 0.8}

@(private = "file")
get_initial_camera :: proc() -> render.Camera {
	return {
		type = .Flying,
		position = INITIAL_CAMERA_POSITION,
		direction = linalg.normalize(INITIAL_CAMERA_TARGET - INITIAL_CAMERA_POSITION),
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

@(private = "file", rodata)
light_position := types.Vec3{1.2, 1, 2}

@(private = "file", rodata)
light_color := types.Vec3{1, 1, 1}

@(private = "file", rodata)
obj_material := render.MaterialCalculated {
	specular  = types.Vec3{1, 1, 1},
	shininess = 32,
}

@(private = "file", rodata)
cube_position := types.Vec3{0, 0, 0}

exercise_04_01_lighting_maps_diffuse_map :: types.Tableau {
	title = "Diffuse map",
	init = proc() {
		shaders.init_shaders(.Light, .PhongDiffuseSampled)
		container_texture = render.prepare_texture("textures/container2.png", .Diffuse, true)
		primitives.cube_send_to_gpu()
		camera = get_initial_camera()
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
	},
	draw = proc() {
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		light_shader := shaders.shaders[.Light]
		obj_shader := shaders.shaders[.PhongDiffuseSampled]

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		pv := projection * view

		model := linalg.matrix4_translate(light_position)
		model *= linalg.matrix4_scale_f32(0.2)
		transform := pv * model

		gl.UseProgram(light_shader)

		shaders.set_vec3(light_shader, "light_color", raw_data(&light_color))
		shaders.set_mat_4x4(light_shader, "transform", raw_data(&transform))

		primitives.cube_draw()

		model = linalg.matrix4_translate(cube_position)
		transform = pv * model
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

		gl.UseProgram(obj_shader)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)

		shaders.set_vec3(obj_shader, "light.position", raw_data(&light_position))
		shaders.set_vec3(obj_shader, "light.ambient", raw_data(&light_color))
		shaders.set_vec3(obj_shader, "light.diffuse", raw_data(&light_color))
		shaders.set_vec3(obj_shader, "light.specular", raw_data(&light_color))

		shaders.set_int(obj_shader, "material.diffuse", 0)
		shaders.set_vec3(obj_shader, "view_position", raw_data(&camera.position))

		shaders.set_mat_4x4(obj_shader, "transform", raw_data(&transform))
		shaders.set_mat_4x4(obj_shader, "model", raw_data(&model))
		shaders.set_mat_3x3(obj_shader, "mit", raw_data(&mit))
		primitives.cube_draw()
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()
		gl.DeleteTextures(1, &container_texture.id)
	},
}
