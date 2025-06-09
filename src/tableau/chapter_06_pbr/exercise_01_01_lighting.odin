package chapter_06_pbr

import "../../primitives"
import "../../shaders"
import "../../types"
import gl "vendor:OpenGL"

exercise_01_01_lighting := types.Tableau {
	init = proc() {
		shaders.init_shaders(.Orange)
		primitives.sphere_init()
		primitives.sphere_send_to_gpu()
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders.shaders[.Orange])
		primitives.sphere_draw()
	},
	teardown = proc() {
		primitives.sphere_clear_from_gpu()
		primitives.sphere_destroy()
	},
}
