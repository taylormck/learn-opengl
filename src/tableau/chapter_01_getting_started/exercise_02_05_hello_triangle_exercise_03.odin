package chapter_01_getting_started

import "../../primitives"
import "../../shaders"
import "../../types"
import gl "vendor:OpenGL"

@(private = "file")
vaos, vbos: [2]u32

@(private = "file")
vertices := [2][3]types.Vec3 {
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

exercise_02_05_hello_triangle_exercise_03 := types.Tableau {
	init = proc() {
		shaders.init_shaders(.Orange, .Yellow)

		gl.GenVertexArrays(2, raw_data(vaos[:]))
		gl.GenBuffers(2, raw_data(vbos[:]))

		defer gl.BindVertexArray(0)
		defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

		for i in 0 ..< 2 {
			gl.BindVertexArray(vaos[i])
			gl.BindBuffer(gl.ARRAY_BUFFER, vbos[i])
			gl.BufferData(gl.ARRAY_BUFFER, size_of(types.Vec3) * 3, raw_data(vertices[i][:]), gl.STATIC_DRAW)

			gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
			gl.EnableVertexAttribArray(0)
		}
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		draw_shaders := [?]u32{shaders.shaders[.Orange], shaders.shaders[.Yellow]}

		defer gl.BindVertexArray(0)

		for i in 0 ..< 2 {
			gl.UseProgram(draw_shaders[i])
			gl.BindVertexArray(vaos[i])
			gl.DrawArrays(gl.TRIANGLES, 0, 3)
		}
	},
	teardown = proc() {
		gl.DeleteVertexArrays(2, raw_data(vaos[:]))
		gl.DeleteBuffers(2, raw_data(vbos[:]))
	},
}
