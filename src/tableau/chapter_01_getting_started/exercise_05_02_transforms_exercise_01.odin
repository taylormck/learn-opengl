package chapter_01_getting_started

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
time: f64 = 0

@(private = "file")
container_texture, awesome_texture: render.Texture

exercise_05_02_transforms_exercise_01 := types.Tableau {
	init = proc() {
		shaders.init_shaders(.TransformDoubleTexture)
		container_texture = render.prepare_texture("textures/container.png", .Diffuse, true)
		awesome_texture = render.prepare_texture("textures/awesomeface.png", .Diffuse, true)
		primitives.quad_send_to_gpu()
	},
	update = proc(delta: f64) {
		time += delta
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, awesome_texture.id)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)

		texture_shader := shaders.shaders[.TransformDoubleTexture]

		transform := linalg.matrix4_rotate_f32(f32(time), {0, 0, 1}) * linalg.matrix4_translate_f32({0.5, -0.5, 0})

		gl.Uniform1i(gl.GetUniformLocation(texture_shader, "diffuse_0"), 0)
		gl.Uniform1i(gl.GetUniformLocation(texture_shader, "diffuse_1"), 1)
		gl.UniformMatrix4fv(gl.GetUniformLocation(texture_shader, "transform"), 1, false, raw_data(&transform))

		gl.UseProgram(texture_shader)
		primitives.quad_draw()
	},
	teardown = proc() {
		primitives.quad_clear_from_gpu()
	},
}
