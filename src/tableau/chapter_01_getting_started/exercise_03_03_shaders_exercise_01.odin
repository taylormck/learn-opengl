package chapter_01_getting_started

import "../../primitives"
import "../../shaders"
import "../../types"
import gl "vendor:OpenGL"

exercise_03_03_shaders_exercise_01 := types.Tableau {
	init = proc() {
		shaders.init_shaders(.UpsideDown)
		primitives.triangle_send_to_gpu()
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders.shaders[.UpsideDown])
		primitives.triangle_draw()
	},
	teardown = proc() {
		primitives.triangle_clear_from_gpu()
	},
}
