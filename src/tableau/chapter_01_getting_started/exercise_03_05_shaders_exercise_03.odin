package chapter_01_getting_started

import "../../primitives"
import "../../shaders"
import "../../types"
import "../../utils"
import "core:log"
import "core:math"
import gl "vendor:OpenGL"

exercise_03_05_shaders_exercise_03 :: types.Tableau {
	title = "Triangle with position as color",
	init = proc() {
		shaders.init_shaders(.PositionAsColor)
		primitives.triangle_send_to_gpu()
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders.shaders[.PositionAsColor])
		primitives.triangle_draw()
	},
	teardown = proc() {
		primitives.triangle_clear_from_gpu()
	},
}

// Question: Why is the bottom-left side of the triangle black?
// Answer: The bottom-left fragments have frag positions where the x and y values are <= 0.
//     These values are clamped to 0, and interpreted as black.
