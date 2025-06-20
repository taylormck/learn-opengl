package chapter_01_getting_started

import "../../primitives"
import "../../shaders"
import "../../types"
import "core:log"
import "core:math"
import gl "vendor:OpenGL"

@(private = "file")
offset := types.Vec3{0.5, 0, 0}

exercise_03_04_shaders_exercise_02 :: types.Tableau {
	init = proc() {
		shaders.init_shaders(.Offset)
		primitives.triangle_send_to_gpu()
	},
	draw = proc() {
		uniform_color_shader := shaders.shaders[.Offset]

		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(uniform_color_shader)
		shaders.set_vec3(uniform_color_shader, "offset", raw_data(&offset))
		primitives.triangle_draw()
	},
	teardown = proc() {
		primitives.triangle_clear_from_gpu()
	},
}
