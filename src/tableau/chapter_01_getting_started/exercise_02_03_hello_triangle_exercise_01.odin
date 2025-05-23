package chapter_01_getting_started

import "../../primitives"
import "../../shaders"
import "../../types"
import gl "vendor:OpenGL"

@(private = "file")
vao, vbo: u32

@(private = "file")
vertices := [6]types.Vec3 {
	{-0.5, -0.5, 0}, // bottom left
	{0, -0.5, 0}, // bottom right
	{-0.25, 0.5, 0}, // top
	{0, -0.5, 0}, // bottom left
	{0.5, -0.5, 0}, // bottom right
	{0.25, 0.5, 0}, // top
}

exercise_02_03_hello_triangle_exercise_01 := types.Tableau {
	init = proc() {
		shaders.init_shaders(.Orange)

		gl.GenVertexArrays(1, &vao)
		gl.GenBuffers(1, &vbo)

		gl.BindVertexArray(vao)
		defer gl.BindVertexArray(0)

		gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
		defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

		gl.BufferData(gl.ARRAY_BUFFER, size_of(types.Vec3) * 6, raw_data(vertices[:]), gl.STATIC_DRAW)

		gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
		gl.EnableVertexAttribArray(0)
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.UseProgram(shaders.shaders[.Orange])

		gl.BindVertexArray(vao)
		defer gl.BindVertexArray(0)

		gl.DrawArrays(gl.TRIANGLES, 0, 6)
	},
	teardown = proc() {
		gl.DeleteVertexArrays(1, &vao)
		gl.DeleteBuffers(1, &vbo)
	},
}
