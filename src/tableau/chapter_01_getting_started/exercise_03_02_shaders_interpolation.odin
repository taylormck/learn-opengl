package chapter_01_getting_started

import "../../primitives"
import "../../shaders"
import "../../types"
import "core:log"
import "core:math"
import gl "vendor:OpenGL"

exercise_03_02_shaders_interpolation :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.VertexColor)
		primitives.triangle_send_to_gpu()
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders.shaders[.VertexColor])
		primitives.triangle_draw()
	},
	teardown = proc() {
		primitives.triangle_clear_from_gpu()
	},
}
