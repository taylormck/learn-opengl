package shaders

import "../types"
import "core:log"
import gl "vendor:OpenGL"

get_uniform_location :: proc(shader: u32, uniform: cstring) -> (location: i32, ok: bool) {
	location = gl.GetUniformLocation(shader, uniform)

	if location == -1 {
		log.errorf("Failed to find location for uniform {} in shader {}.", uniform, shader)
		return
	}

	return location, true
}

set_bool :: proc(shader: u32, uniform: cstring, value: bool) -> (ok: bool) {
	location := get_uniform_location(shader, uniform) or_return
	gl.Uniform1i(location, i32(value))
	return true
}

set_int :: proc(shader: u32, uniform: cstring, value: i32) -> (ok: bool) {
	location := get_uniform_location(shader, uniform) or_return
	gl.Uniform1i(location, value)
	return true
}

set_float :: proc(shader: u32, uniform: cstring, value: f32) -> (ok: bool) {
	location := get_uniform_location(shader, uniform) or_return
	gl.Uniform1f(location, value)
	return true
}

set_vec3 :: proc(shader: u32, uniform: cstring, data: [^]f32) -> (ok: bool) {
	location := get_uniform_location(shader, uniform) or_return
	gl.Uniform3fv(location, 1, data)
	return true
}

set_vec4 :: proc(shader: u32, uniform: cstring, data: [^]f32) -> (ok: bool) {
	location := get_uniform_location(shader, uniform) or_return
	gl.Uniform4fv(location, 1, data)
	return true
}

set_mat_3x3 :: proc(shader: u32, uniform: cstring, data: [^]f32) -> (ok: bool) {
	location := get_uniform_location(shader, uniform) or_return
	gl.UniformMatrix3fv(location, 1, false, data)
	return true
}

set_mat_4x4 :: proc(shader: u32, uniform: cstring, data: [^]f32) -> (ok: bool) {
	location := get_uniform_location(shader, uniform) or_return
	gl.UniformMatrix4fv(location, 1, false, data)
	return true
}
