package utils

import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"

print_gl_errors :: proc(location := #caller_location) {
	for err := gl.GetError(); err != gl.NO_ERROR; err = gl.GetError() {
		err_msg: string

		switch (err) {
		case gl.INVALID_OPERATION:
			err_msg = "Invalid operation"
		case gl.INVALID_ENUM:
			err_msg = "Invalid enum"
		case gl.INVALID_VALUE:
			err_msg = "Invalid value"
		case gl.STACK_OVERFLOW:
			err_msg = "Stack overflow"
		case gl.STACK_UNDERFLOW:
			err_msg = "Stack underflow"
		case gl.OUT_OF_MEMORY:
			err_msg = "Out of memory"
		case gl.INVALID_FRAMEBUFFER_OPERATION:
			err_msg = "Invalid framebuffer operation"
		case:
			err_msg = fmt.tprintf("Untranslated error: {}", err)
		}

		log.errorf("OpenGL Error: {}", err_msg, location = location)
	}
}

get_current_vao :: proc() -> i32 {
	vao: i32 = ---
	gl.GetIntegerv(gl.VERTEX_ARRAY_BINDING, &vao)

	return vao
}

get_current_vbo :: proc() -> i32 {
	vbo: i32 = ---
	gl.GetIntegerv(gl.ARRAY_BUFFER_BINDING, &vbo)

	return vbo
}
