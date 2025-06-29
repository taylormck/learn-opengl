package chapter_05_advanced_lighting

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
light_position := types.Vec3{-2, 4, 1}

@(private = "file")
light := render.DirectionalLight {
	direction = -light_position,
	ambient   = {0.2, 0.2, 0.2},
	diffuse   = {0.5, 0.5, 0.5},
	specular  = {1, 1, 1},
}

@(private = "file")
cube_transforms := [?]types.TransformMatrix {
	linalg.matrix4_translate_f32({0, 1.5, 0}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({2, 0, 1}) * linalg.matrix4_scale_f32(0.5),
	linalg.matrix4_translate_f32({-1, 0, 2}) *
	linalg.matrix4_rotate_f32(linalg.to_radians(f32(60)), linalg.normalize(types.Vec3{1, 0, 1})) *
	linalg.matrix4_scale_f32(0.25),
}

@(private = "file")
near: f32 = 1.0

@(private = "file")
far: f32 = 7.5

@(private = "file")
light_projection := linalg.matrix_ortho3d_f32(
	left = -10.0,
	right = 10.0,
	bottom = -10.0,
	top = 10.0,
	near = near,
	far = far,
)

@(private = "file")
shininess: f32 = 32

@(private = "file")
material_specular := types.Vec3{0.5, 0.5, 0.5}

@(private = "file")
light_view := linalg.matrix4_look_at_f32(eye = light_position, centre = types.Vec3{0, 0, 0}, up = types.Vec3{0, 1, 0})

@(private = "file")
light_projection_view := light_projection * light_view

@(private = "file")
depth_fbo, depth_fb_texture: u32

@(private = "file")
shadow_width, shadow_height: i32 = 1024, 1024

@(private = "file")
shadow_border_color := types.Vec4{1, 1, 1, 1}

exercise_03_01_03_shadow_mapping :: types.Tableau {
	title = "Shadow mapping",
	init = proc() {
		wood_texture = render.prepare_texture("textures/wood.png", .Diffuse, true)
		shaders.init_shaders(.EmptyDepth, .BlinnPhongDirectionalShadow2)

		primitives.plane_send_to_gpu()
		primitives.cube_send_to_gpu()

		camera = get_initial_camera()

		gl.GenFramebuffers(1, &depth_fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, depth_fbo)

		gl.GenTextures(1, &depth_fb_texture)
		gl.BindTexture(gl.TEXTURE_2D, depth_fb_texture)

		gl.TexImage2D(
			gl.TEXTURE_2D,
			0,
			gl.DEPTH_COMPONENT,
			shadow_width,
			shadow_height,
			0,
			gl.DEPTH_COMPONENT,
			gl.FLOAT,
			nil,
		)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameterfv(gl.TEXTURE_2D, gl.TEXTURE_BORDER_COLOR, raw_data(&shadow_border_color))
		gl.BindTexture(gl.TEXTURE_2D, 0)

		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, depth_fb_texture, 0)
		gl.DrawBuffer(gl.NONE)
		gl.ReadBuffer(gl.NONE)

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	},
	update = proc(delta: f64) {
		render.camera_common_update(&camera, delta)
	},
	draw = proc() {
		depth_shader := shaders.shaders[.EmptyDepth]
		scene_shader := shaders.shaders[.BlinnPhongDirectionalShadow2]

		// Render shadow map
		gl.Viewport(0, 0, shadow_width, shadow_height)
		gl.BindFramebuffer(gl.FRAMEBUFFER, depth_fbo)
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)

		gl.UseProgram(depth_shader)
		render_scene(depth_shader, &light_projection_view)

		// Render scene
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.Viewport(0, 0, window.width, window.height)
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, wood_texture.id)

		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, depth_fb_texture)

		projection := render.camera_get_projection(&camera)
		view := render.camera_get_view(&camera)
		projection_view := projection * view

		gl.UseProgram(scene_shader)

		render.directional_light_set_uniform(&light, scene_shader)

		shaders.set_int(scene_shader, "material.diffuse_0", 0)
		shaders.set_float(scene_shader, "material.shininess", shininess)
		shaders.set_vec3(scene_shader, "material.specular", raw_data(&material_specular))

		shaders.set_int(scene_shader, "shadow_map", 1)
		shaders.set_vec3(scene_shader, "view_position", raw_data(&camera.position))

		shaders.set_mat_4x4(scene_shader, "light_projection_view", raw_data(&light_projection_view))

		render_scene(scene_shader, &projection_view)
	},
	teardown = proc() {
		primitives.plane_clear_from_gpu()
		primitives.cube_clear_from_gpu()

		gl.DeleteTextures(1, &depth_fb_texture)
		gl.DeleteFramebuffers(1, &depth_fbo)

		gl.DeleteTextures(1, &wood_texture.id)
	},
}

@(private = "file")
render_scene :: proc(shader: u32, projection_view: ^types.TransformMatrix) {

	// Draw cubes
	for &model, i in cube_transforms {
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
		transform := projection_view^ * model

		shaders.set_mat_4x4(shader, "transform", raw_data(&transform))
		if shader != shaders.shaders[.EmptyDepth] {
			shaders.set_mat_4x4(shader, "model", raw_data(&model))
			shaders.set_mat_3x3(shader, "mit", raw_data(&mit))
		}

		primitives.cube_draw()
	}

	// Render plane
	{
		model := linalg.identity(types.TransformMatrix)
		mit := linalg.identity(types.SubTransformMatrix)

		shaders.set_mat_4x4(shader, "transform", raw_data(projection_view))
		if shader != shaders.shaders[.EmptyDepth] {
			shaders.set_mat_4x4(shader, "model", raw_data(&model))
			shaders.set_mat_3x3(shader, "mit", raw_data(&mit))
		}

		primitives.plane_draw()
	}
}
