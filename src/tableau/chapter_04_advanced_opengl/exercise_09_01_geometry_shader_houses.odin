package chapter_04_advanced_opengl

import "../../primitives"
import "../../shaders"
import "../../types"
import gl "vendor:OpenGL"

@(private = "file", rodata)
background_color := types.Vec3{0.1, 0.1, 0.1}

exercise_09_01_geometry_shader_houses :: types.Tableau {
	title = "Geometry shaders in practice",
	init = proc() {
		primitives.points_send_to_gpu()
		shaders.init_shaders(.House)
	},
	draw = proc() {
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.Disable(gl.DEPTH_TEST)

		house_shader := shaders.shaders[.House]

		gl.UseProgram(house_shader)
		primitives.points_draw()
	},
	teardown = proc() {
		primitives.points_clear_from_gpu()
	},
}
