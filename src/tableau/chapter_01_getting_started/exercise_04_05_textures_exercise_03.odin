package chapter_01_getting_started

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import gl "vendor:OpenGL"

@(private = "file")
container_texture, awesome_texture: render.Texture

exercise_04_05_textures_exercise_03 :: types.Tableau {
	title = "Quad with pixelated texture",
	init = proc() {
		shaders.init_shaders(.DoubleTexture)

		// NOTE: render.prepare_texture sets the interpolation method to bilinear, but we want nearest
		container_texture = render.prepare_texture("textures/container.png", .Diffuse, true)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.BindTexture(gl.TEXTURE_2D, 0)

		awesome_texture = render.prepare_texture("textures/awesomeface.png", .Diffuse, true)
		gl.BindTexture(gl.TEXTURE_2D, awesome_texture.id)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.BindTexture(gl.TEXTURE_2D, 0)
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, container_texture.id)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, awesome_texture.id)
		defer gl.BindTexture(gl.TEXTURE_2D, 0)

		texture_shader := shaders.shaders[.DoubleTexture]
		gl.UseProgram(texture_shader)

		shaders.set_int(texture_shader, "diffuse_0", 0)
		shaders.set_int(texture_shader, "diffuse_1", 1)

		primitives.quad_draw()
	},
	teardown = proc() {
		gl.DeleteTextures(1, &container_texture.id)
		gl.DeleteTextures(1, &awesome_texture.id)
	},
}
