package chapter_01_getting_started

import "../../types"
import gl "vendor:OpenGL"

exercise_01_02_hello_window_clear :: types.Tableau {
	init = proc() {},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
	},
	teardown = proc() {},
}
