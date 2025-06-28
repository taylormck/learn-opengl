package chapter_01_getting_started

import "../../primitives"
import "../../shaders"
import "../../types"
import gl "vendor:OpenGL"

exercise_02_02_hello_triangle_indexed :: types.Tableau {
	title = "Quad",
	init = proc() {
		shaders.init_shaders(.Orange)
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders.shaders[.Orange])
		primitives.quad_draw()
	},
}

exercise_02_02_hello_triangle_indexed_wireframe :: types.Tableau {
	title = "Quad wireframe",
	init = proc() {
		shaders.init_shaders(.Orange)
	},
	draw = proc() {
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
		defer gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)

		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders.shaders[.Orange])
		primitives.quad_draw()
	},
}
