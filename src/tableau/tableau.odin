package tableau

import "../primitives"
import "../types"
import gl "vendor:OpenGL"

Tableau :: struct {
	init:     #type proc(),
	draw:     #type proc(delta: f64),
	teardown: #type proc(),
}

NOOP_INIT :: proc() {}
NOOP_DRAW :: proc(delta: f64) {}
NOOP_TEARDOWN :: proc() {}

hello_window_tableau := Tableau {
	init     = NOOP_INIT,
	draw     = NOOP_DRAW,
	teardown = NOOP_TEARDOWN,
}

clear_window_tableau := Tableau {
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

two_triangles_vao, two_triangles_vbo: u32
two_triangles_vertices := [6]types.Vec3 {
	{-0.5, -0.5, 0}, // bottom left
	{0, -0.5, 0}, // bottom right
	{-0.25, 0.5, 0}, // top
	{0, -0.5, 0}, // bottom left
	{0.5, -0.5, 0}, // bottom right
	{0.25, 0.5, 0}, // top
}
two_orange_triangles_same_buffers_tableau := Tableau {
	init = proc() {
		init_shaders(.Orange)

		gl.GenVertexArrays(1, &two_triangles_vao)
		gl.GenBuffers(1, &two_triangles_vbo)

		gl.BindVertexArray(two_triangles_vao)
		defer gl.BindVertexArray(0)

		gl.BindBuffer(gl.ARRAY_BUFFER, two_triangles_vbo)
		defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

		gl.BufferData(gl.ARRAY_BUFFER, size_of(types.Vec3) * 6, raw_data(two_triangles_vertices[:]), gl.STATIC_DRAW)

		gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
		gl.EnableVertexAttribArray(0)
	},
	draw = proc(delta: f64) {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders[.Orange])

		gl.BindVertexArray(two_triangles_vao)
		defer gl.BindVertexArray(0)

		gl.DrawArrays(gl.TRIANGLES, 0, 6)
	},
	teardown = proc() {
		gl.DeleteVertexArrays(1, &two_triangles_vao)
		gl.DeleteBuffers(1, &two_triangles_vbo)
	},
}

two_triangles_vaos, two_triangles_vbos: [2]u32
two_triangles_vertices_array := [2][3]types.Vec3 {
	{
		{-0.5, -0.5, 0}, // bottom left
		{0, -0.5, 0}, // bottom right
		{-0.25, 0.5, 0}, // top
	},
	{
		{0, -0.5, 0}, // bottom left
		{0.5, -0.5, 0}, // bottom right
		{0.25, 0.5, 0}, // top
	},
}
two_orange_triangles_separate_buffers_tableau := Tableau {
	init = proc() {
		init_shaders(.Orange)

		gl.GenVertexArrays(2, raw_data(two_triangles_vaos[:]))
		gl.GenBuffers(2, raw_data(two_triangles_vbos[:]))

		defer gl.BindVertexArray(0)
		defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

		for i in 0 ..< 2 {
			gl.BindVertexArray(two_triangles_vaos[i])
			gl.BindBuffer(gl.ARRAY_BUFFER, two_triangles_vbos[i])
			gl.BufferData(
				gl.ARRAY_BUFFER,
				size_of(types.Vec3) * 3,
				raw_data(two_triangles_vertices_array[i][:]),
				gl.STATIC_DRAW,
			)

			gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
			gl.EnableVertexAttribArray(0)
		}
	},
	draw = proc(delta: f64) {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders[.Orange])

		defer gl.BindVertexArray(0)

		for i in 0 ..< 2 {
			gl.BindVertexArray(two_triangles_vaos[i])
			gl.DrawArrays(gl.TRIANGLES, 0, 3)
		}
	},
	teardown = proc() {
		gl.DeleteVertexArrays(2, raw_data(two_triangles_vaos[:]))
		gl.DeleteBuffers(2, raw_data(two_triangles_vbos[:]))
	},
}

two_triangles_different_colors_tableau := Tableau {
	init = proc() {
		init_shaders(.Orange, .Yellow)

		gl.GenVertexArrays(2, raw_data(two_triangles_vaos[:]))
		gl.GenBuffers(2, raw_data(two_triangles_vbos[:]))

		defer gl.BindVertexArray(0)
		defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

		for i in 0 ..< 2 {
			gl.BindVertexArray(two_triangles_vaos[i])
			gl.BindBuffer(gl.ARRAY_BUFFER, two_triangles_vbos[i])
			gl.BufferData(
				gl.ARRAY_BUFFER,
				size_of(types.Vec3) * 3,
				raw_data(two_triangles_vertices_array[i][:]),
				gl.STATIC_DRAW,
			)

			gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
			gl.EnableVertexAttribArray(0)
		}
	},
	draw = proc(delta: f64) {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		draw_shaders := [?]u32{shaders[.Orange], shaders[.Yellow]}

		defer gl.BindVertexArray(0)

		for i in 0 ..< 2 {
			gl.UseProgram(draw_shaders[i])
			gl.BindVertexArray(two_triangles_vaos[i])
			gl.DrawArrays(gl.TRIANGLES, 0, 3)
		}
	},
	teardown = proc() {
		gl.DeleteVertexArrays(2, raw_data(two_triangles_vaos[:]))
		gl.DeleteBuffers(2, raw_data(two_triangles_vbos[:]))
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
