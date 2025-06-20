package chapter_01_getting_started

import "../../primitives"
import "../../shaders"
import "../../types"
import "core:log"
import "core:math"
import gl "vendor:OpenGL"

@(private = "file")
tableau_time: f64 = 0

exercise_03_01_shaders_uniform :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.UniformColor)
		primitives.triangle_send_to_gpu()
	},
	update = proc(delta: f64) {
		tableau_time += delta
	},
	draw = proc() {
		uniform_color := types.Vec4{0, math.sin(f32(tableau_time)) / 2 + 0.5, 0, 1}
		uniform_color_shader := shaders.shaders[.UniformColor]

		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(uniform_color_shader)
		shaders.set_vec4(uniform_color_shader, "our_color", raw_data(&uniform_color))
		primitives.triangle_draw()
	},
	teardown = proc() {
		primitives.triangle_clear_from_gpu()
	},
}
