package tableau

import "../primitives"
import gl "vendor:OpenGL"

Tableau :: struct {
	init:     #type proc(),
	draw:     #type proc(delta: f64),
	teardown: #type proc(),
}

NOOP_INIT :: proc() {}
NOOP_DRAW :: proc(delta: f64) {}
NOOP_TEARDOWN :: proc() {}

empty_window_tableau := Tableau {
	init = NOOP_INIT,
	draw = proc(delta: f64) {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
	},
	teardown = NOOP_TEARDOWN,
}

orange_triangle_tableau := Tableau {
	init = proc() {
		init_shaders(.Orange)
		primitives.triangle_send_to_gpu()
	},
	draw = proc(delta: f64) {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders[.Orange])
		primitives.triangle_draw()
	},
	teardown = proc() {
		primitives.triangle_clear_from_gpu()
	},
}

orange_quad_tableau := Tableau {
	init = proc() {
		init_shaders(.Orange)
		primitives.quad_send_to_gpu()
	},
	draw = proc(delta: f64) {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders[.Orange])
		primitives.quad_draw()
	},
	teardown = proc() {
		primitives.triangle_clear_from_gpu()
	},
}

orange_quad_wireframe_tableau := Tableau {
	init = proc() {
		init_shaders(.Orange)
		primitives.quad_send_to_gpu()
	},
	draw = proc(delta: f64) {
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
		defer gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)

		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders[.Orange])
		primitives.quad_draw()
	},
	teardown = proc() {
		primitives.triangle_clear_from_gpu()
	},
}

color_triangle_tableau := Tableau {
	init = proc() {
		init_shaders(.VertexColor)
		primitives.triangle_send_to_gpu()
	},
	draw = proc(delta: f64) {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders[.VertexColor])
		primitives.triangle_draw()
	},
	teardown = proc() {
		primitives.triangle_clear_from_gpu()
	},
}
