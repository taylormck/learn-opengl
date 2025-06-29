package chapter_05_advanced_lighting

import "../../input"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec3{0, 0, 0}

@(private = "file")
wood_texture: render.Texture

@(private = "file")
INITIAL_CAMERA_POSITION :: types.Vec3{-3, 2, 4}

@(private = "file")
INITIAL_CAMERA_TARGET :: types.Vec3{0, -0.5, 0}

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

@(private = "file")
light := render.PointLight {
	position  = types.Vec3{0, 0, 0},
	ambient   = {0.2, 0.2, 0.2},
	diffuse   = {0.5, 0.5, 0.5},
	specular  = {1, 1, 1},
	constant  = 1,
	linear    = 0.09,
	quadratic = 0.032,
}

@(private = "file")
cube_transforms := [?]types.TransformMatrix {
	linalg.matrix4_translate_f32({4, -3.5, 0}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({2, 3, 1}) * linalg.matrix4_scale_f32(0.75),
	linalg.matrix4_translate_f32({-3, -1, 0}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({-1.5, 1, 1.5}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({-1.5, 2, -3}) *
	linalg.matrix4_rotate_f32(linalg.to_radians(f32(60)), linalg.normalize(types.Vec3{1, 0, 1})) *
	linalg.matrix4_scale_f32(0.75),
}

@(private = "file")
near: f32 = 1.0

@(private = "file")
far: f32 = 25.0

@(private = "file")
shininess: f32 = 32

@(private = "file")
material_specular := types.Vec3{0.5, 0.5, 0.5}

@(private = "file")
depth_fbo, depth_cube_map: u32

@(private = "file")
shadow_width, shadow_height: i32 = 1024, 1024

@(private = "file")
shadow_border_color := types.Vec4{1, 1, 1, 1}

@(private = "file")
shadow_projection := linalg.matrix4_perspective_f32(
	fovy = linalg.to_radians(f32(90)),
	aspect = f32(shadow_width) / f32(shadow_height),
	near = near,
	far = far,
)

@(private = "file")
shadow_transforms := [?]types.TransformMatrix {
	shadow_projection *
	linalg.matrix4_look_at_f32(
		eye = light.position,
		centre = light.position + types.Vec3{1, 0, 0},
		up = types.Vec3{0, -1, 0},
	),
	shadow_projection *
	linalg.matrix4_look_at_f32(
		eye = light.position,
		centre = light.position + types.Vec3{-1, 0, 0},
		up = types.Vec3{0, -1, 0},
	),
	shadow_projection *
	linalg.matrix4_look_at_f32(
		eye = light.position,
		centre = light.position + types.Vec3{0, 1, 0},
		up = types.Vec3{0, 0, 1},
	),
	shadow_projection *
	linalg.matrix4_look_at_f32(
		eye = light.position,
		centre = light.position + types.Vec3{0, -1, 0},
		up = types.Vec3{0, 0, -1},
	),
	shadow_projection *
	linalg.matrix4_look_at_f32(
		eye = light.position,
		centre = light.position + types.Vec3{0, 0, 1},
		up = types.Vec3{0, -1, 0},
	),
	shadow_projection *
	linalg.matrix4_look_at_f32(
		eye = light.position,
		centre = light.position + types.Vec3{0, 0, -1},
		up = types.Vec3{0, -1, 0},
	),
}

@(private = "file")
debug := false

exercise_03_02_01_point_shadows :: types.Tableau {
	title = "Point shadows",
	help_text = "Press [SPACE] to show debug map",
	init = proc() {
		wood_texture = render.prepare_texture("textures/wood.png", .Diffuse, true)
		shaders.init_shaders(.DepthCube, .BlinnPhongDirectionalShadow3)

		primitives.cube_send_to_gpu()

		camera = get_initial_camera()

		gl.GenTextures(1, &depth_cube_map)
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, depth_cube_map)

		for i in 0 ..< 6 {
			gl.TexImage2D(
				gl.TEXTURE_CUBE_MAP_POSITIVE_X + u32(i),
				0,
				gl.DEPTH_COMPONENT,
				shadow_width,
				shadow_height,
				0,
				gl.DEPTH_COMPONENT,
				gl.FLOAT,
				nil,
			)
		}

		gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)

		gl.GenFramebuffers(1, &depth_fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, depth_fbo)
		gl.FramebufferTexture(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, depth_cube_map, 0)
		gl.DrawBuffer(gl.NONE)
		gl.ReadBuffer(gl.NONE)

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)

		if .Space in input.input_state.pressed_keys do debug = !debug
	},
	draw = proc() {
		depth_shader := shaders.shaders[.DepthCube]
		scene_shader := shaders.shaders[.BlinnPhongDirectionalShadow3]

		// // Render shadow map
		gl.Viewport(0, 0, shadow_width, shadow_height)
		gl.BindFramebuffer(gl.FRAMEBUFFER, depth_fbo)
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.DEPTH_TEST)
		defer gl.Disable(gl.DEPTH_TEST)

		gl.Enable(gl.CULL_FACE)
		defer gl.Disable(gl.CULL_FACE)

		gl.UseProgram(depth_shader)
		for &transform, i in shadow_transforms {
			uniform_name := fmt.ctprintf("shadow_matrices[{}]", i)
			shaders.set_mat_4x4(depth_shader, uniform_name, raw_data(&transform))
		}

		fake_pv := linalg.identity(types.TransformMatrix)
		shaders.set_float(depth_shader, "far_plane", far)
		shaders.set_vec3(depth_shader, "light_position", raw_data(&light.position))

		render_scene(depth_shader, &fake_pv)

		// // Render scene
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.Viewport(0, 0, window.width, window.height)
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, wood_texture.id)

		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, depth_cube_map)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		projection_view := projection * view

		gl.UseProgram(scene_shader)

		render.point_light_set_uniform(&light, scene_shader)

		shaders.set_int(scene_shader, "material.diffuse_0", 0)
		shaders.set_float(scene_shader, "material.shininess", shininess)
		shaders.set_vec3(scene_shader, "material.specular", raw_data(&material_specular))

		shaders.set_int(scene_shader, "debug", i32(debug))
		shaders.set_int(scene_shader, "depth_map", 1)
		shaders.set_float(scene_shader, "far_plane", far)
		shaders.set_vec3(scene_shader, "view_position", raw_data(&camera.position))

		render_scene(scene_shader, &projection_view)
	},
	teardown = proc() {
		primitives.cube_clear_from_gpu()

		gl.DeleteTextures(1, &depth_cube_map)
		gl.DeleteFramebuffers(1, &depth_fbo)

		gl.DeleteTextures(1, &wood_texture.id)
	},
}

@(private = "file")
render_scene :: proc(shader: u32, projection_view: ^types.TransformMatrix) {
	gl.UseProgram(shader)

	if shader != shaders.shaders[.DepthCube] do shaders.set_int(shader, "reverse_normals", 0)

	// Draw cubes
	for &model, i in cube_transforms {
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
		transform := projection_view^ * model

		shaders.set_mat_4x4(shader, "model", raw_data(&model))

		if shader != shaders.shaders[.DepthCube] {
			shaders.set_mat_4x4(shader, "transform", raw_data(&transform))
			shaders.set_mat_3x3(shader, "mit", raw_data(&mit))
		}

		primitives.cube_draw()
	}

	// Render outside cube
	{
		model := linalg.matrix4_scale_f32(10)
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
		transform := projection_view^ * model

		shaders.set_mat_4x4(shader, "model", raw_data(&model))

		if shader != shaders.shaders[.DepthCube] {
			shaders.set_mat_4x4(shader, "transform", raw_data(&transform))
			shaders.set_mat_3x3(shader, "mit", raw_data(&mit))
		}

		gl.CullFace(gl.FRONT)
		defer gl.CullFace(gl.BACK)

		if shader != shaders.shaders[.DepthCube] do shaders.set_int(shader, "reverse_normals", 1)
		defer if shader != shaders.shaders[.DepthCube] do shaders.set_int(shader, "reverse_normals", 0)


		primitives.cube_draw()
	}
}
