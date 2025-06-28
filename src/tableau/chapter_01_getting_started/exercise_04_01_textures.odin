package chapter_01_getting_started

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../utils"
import gl "vendor:OpenGL"

@(private = "file")
container_texture: render.Texture

exercise_04_01_textures :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.Texture)
		container_texture = render.prepare_texture("textures/container.png", .Diffuse, true)
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)

		texture_shader := shaders.shaders[.Texture]
		gl.UseProgram(texture_shader)

		shaders.set_int(texture_shader, "diffuse_0", 0)
		primitives.quad_draw()
	},
	teardown = proc() {
		gl.DeleteTextures(1, &container_texture.id)
	},
}

exercise_04_01_textures_color :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.ColorTexture)
		container_texture = render.prepare_texture("textures/container.png", .Diffuse, true)
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)

		texture_shader := shaders.shaders[.ColorTexture]
		gl.UseProgram(texture_shader)

		shaders.set_int(texture_shader, "diffuse_0", 0)

		primitives.quad_draw()
	},
	teardown = proc() {
		gl.DeleteTextures(1, &container_texture.id)
	},
}
