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

@(private = "file")
background_color := types.Vec3{0, 0, 0}

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
light_position := types.Vec3{-2, 4, -1}

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
light_view := linalg.matrix4_look_at_f32(eye = light_position, centre = types.Vec3{0, 0, 0}, up = types.Vec3{0, 1, 0})

@(private = "file")
light_projection_view := light_projection * light_view

@(private = "file")
depth_fbo, depth_fb_texture: u32

@(private = "file")
shadow_width, shadow_height: i32 = 1024, 1024

exercise_03_01_01_depth := types.Tableau {
	init = proc() {
		shaders.init_shaders(.EmptyDepth, .DepthR)
		primitives.plane_send_to_gpu()
		primitives.cube_send_to_gpu()
		primitives.full_screen_send_to_gpu()

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
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
		gl.BindTexture(gl.TEXTURE_2D, 0)

		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, depth_fb_texture, 0)
		gl.DrawBuffer(gl.NONE)
		gl.ReadBuffer(gl.NONE)

		// if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE do panic("Framebuffer incomplete!")
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	},
	update = proc(delta: f64) {},
	draw = proc() {
		depth_shader := shaders.shaders[.EmptyDepth]
		texture_shader := shaders.shaders[.DepthR]

		// Render shadow map
		gl.Viewport(0, 0, shadow_width, shadow_height)
		gl.BindFramebuffer(gl.FRAMEBUFFER, depth_fbo)
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.DEPTH_BUFFER_BIT)
		gl.Enable(gl.DEPTH_TEST)

		render_scene(depth_shader, &light_projection_view)

		// Render texture to screen
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.Viewport(0, 0, window.width, window.height)
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.Disable(gl.DEPTH_TEST)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, depth_fb_texture)

		gl.UseProgram(texture_shader)
		gl.Uniform1f(gl.GetUniformLocation(texture_shader, "near"), near)
		gl.Uniform1f(gl.GetUniformLocation(texture_shader, "far"), far)
		gl.Uniform1i(gl.GetUniformLocation(texture_shader, "linearize"), 0)
		gl.Uniform1i(gl.GetUniformLocation(texture_shader, "depth_map"), 0)
		primitives.full_screen_draw()
	},
	teardown = proc() {
		primitives.plane_clear_from_gpu()
		primitives.cube_clear_from_gpu()
		primitives.full_screen_clear_from_gpu()

		gl.DeleteTextures(1, &depth_fb_texture)
		gl.DeleteFramebuffers(1, &depth_fbo)
	},
}

render_scene :: proc(shader: u32, projection_view: ^types.TransformMatrix) {
	gl.UseProgram(shader)

	// Draw cubes
	for model, i in cube_transforms {
		transform := projection_view^ * model
		gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "transform"), 1, false, raw_data(&transform))

		primitives.cube_draw()
	}

	// Render plane
	{
		gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "transform"), 1, false, raw_data(projection_view))
		primitives.plane_draw()
	}
}
