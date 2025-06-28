package chapter_01_getting_started

import "../../input"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import gl "vendor:OpenGL"

@(private = "file")
ratio: f32 = 0.5

@(private = "file")
container_texture, awesome_texture: render.Texture

exercise_04_06_textures_exercise_04 :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.Exercise_04_06)
		container_texture = render.prepare_texture("textures/container.png", .Diffuse, true)
		awesome_texture = render.prepare_texture("textures/awesomeface.png", .Diffuse, true)
	},
	update = proc(delta: f64) {
		ratio_scale :: 0.4
		ratio += input.input_state.movement.z * ratio_scale * f32(delta)
		ratio = clamp(ratio, 0, 1)
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, awesome_texture.id)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)

		texture_shader := shaders.shaders[.Exercise_04_06]
		gl.UseProgram(texture_shader)

		shaders.set_int(texture_shader, "diffuse_0", 0)
		shaders.set_int(texture_shader, "diffuse_1", 1)
		shaders.set_float(texture_shader, "ratio", ratio)
		primitives.quad_draw()
	},
	teardown = proc() {
		gl.DeleteTextures(1, &container_texture.id)
		gl.DeleteTextures(1, &awesome_texture.id)
	},
}
