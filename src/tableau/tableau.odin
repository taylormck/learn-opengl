package tableau

import "../primitives"
import gl "vendor:OpenGL"

Tableau :: struct {
	init:     #type proc(),
	draw:     #type proc(delta: f64),
	teardown: #type proc(),
}

triangle_tableau := Tableau {
	init = proc() {
		init_shaders(.VertexColor)
		primitives.triangle_send_to_gpu()
	},
	draw = proc(delta: f64) {
		gl.ClearColor(0.1, 0.2, 0.3, 1)
		gl.UseProgram(shaders[.VertexColor])
		primitives.triangle_draw()
	},
	teardown = proc() {
		primitives.triangle_clear_from_gpu()
	},
}
