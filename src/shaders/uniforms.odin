package shaders

import "../types"
import "core:log"
import gl "vendor:OpenGL"

get_uniform_location :: proc(
	shader: u32,
	uniform: cstring,
	caller_location := #caller_location,
) -> (
	uniform_location: i32,
	ok: bool,
) {
	uniform_location = gl.GetUniformLocation(shader, uniform)

	if uniform_location == -1 {
		log.errorf("Failed to find location for uniform {} in shader {}.", uniform, shader, location = caller_location)
		return
	}

	return uniform_location, true
}

set_bool :: proc(shader: u32, uniform: cstring, value: bool, caller_location := #caller_location) -> (ok: bool) {
	uniform_location := get_uniform_location(shader, uniform, caller_location) or_return
	gl.Uniform1i(uniform_location, i32(value))
	return true
}

set_int :: proc(shader: u32, uniform: cstring, value: i32, caller_location := #caller_location) -> (ok: bool) {
	uniform_location := get_uniform_location(shader, uniform, caller_location) or_return
	gl.Uniform1i(uniform_location, value)
	return true
}

set_float :: proc(shader: u32, uniform: cstring, value: f32, caller_location := #caller_location) -> (ok: bool) {
	uniform_location := get_uniform_location(shader, uniform, caller_location) or_return
	gl.Uniform1f(uniform_location, value)
	return true
}

set_vec3 :: proc(shader: u32, uniform: cstring, data: [^]f32, caller_location := #caller_location) -> (ok: bool) {
	uniform_location := get_uniform_location(shader, uniform, caller_location) or_return
	gl.Uniform3fv(uniform_location, 1, data)
	return true
}

set_vec4 :: proc(shader: u32, uniform: cstring, data: [^]f32, caller_location := #caller_location) -> (ok: bool) {
	uniform_location := get_uniform_location(shader, uniform, caller_location) or_return
	gl.Uniform4fv(uniform_location, 1, data)
	return true
}

set_mat_3x3 :: proc(shader: u32, uniform: cstring, data: [^]f32, caller_location := #caller_location) -> (ok: bool) {
	uniform_location := get_uniform_location(shader, uniform, caller_location) or_return
	gl.UniformMatrix3fv(uniform_location, 1, false, data)
	return true
}

set_mat_4x4 :: proc(shader: u32, uniform: cstring, data: [^]f32, caller_location := #caller_location) -> (ok: bool) {
	uniform_location := get_uniform_location(shader, uniform, caller_location) or_return
	gl.UniformMatrix4fv(uniform_location, 1, false, data)
	return true
}
