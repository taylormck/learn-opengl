package render

import "../shaders"
import "../types"
import "core:fmt"
import gl "vendor:OpenGL"

PointLight :: struct {
	position, ambient, diffuse, specular, emissive: types.Vec3,
	constant, linear, quadratic:                    f32,
}

DirectionalLight :: struct {
	direction, ambient, diffuse, specular: types.Vec3,
}

SpotLight :: struct {
	position, direction, ambient, diffuse, specular:         types.Vec3,
	inner_cutoff, outer_cutoff, constant, linear, quadratic: f32,
}

point_light_set_uniform :: proc(light: ^PointLight, shader_id: u32) {
	shaders.set_vec3(shader_id, "point_light.position", raw_data(&light.position))
	shaders.set_vec3(shader_id, "point_light.ambient", raw_data(&light.ambient))
	shaders.set_vec3(shader_id, "point_light.diffuse", raw_data(&light.diffuse))
	shaders.set_vec3(shader_id, "point_light.specular", raw_data(&light.specular))
	shaders.set_vec3(shader_id, "point_light.emissive", raw_data(&light.emissive))

	shaders.set_float(shader_id, "point_light.constant", light.constant)
	shaders.set_float(shader_id, "point_light.linear", light.linear)
	shaders.set_float(shader_id, "point_light.quadratic", light.quadratic)
}

point_light_array_set_uniform :: proc(light: ^PointLight, shader_id: u32, index: u32) {
	gl.Uniform3fv(
		gl.GetUniformLocation(shader_id, fmt.ctprintf("point_lights[{}].position", index)),
		1,
		raw_data(&light.position),
	)

	gl.Uniform3fv(
		gl.GetUniformLocation(shader_id, fmt.ctprintf("point_lights[{}].ambient", index)),
		1,
		raw_data(&light.ambient),
	)

	gl.Uniform3fv(
		gl.GetUniformLocation(shader_id, fmt.ctprintf("point_lights[{}].diffuse", index)),
		1,
		raw_data(&light.diffuse),
	)

	gl.Uniform3fv(
		gl.GetUniformLocation(shader_id, fmt.ctprintf("point_lights[{}].specular", index)),
		1,
		raw_data(&light.specular),
	)

	gl.Uniform3fv(
		gl.GetUniformLocation(shader_id, fmt.ctprintf("point_lights[{}].emissive", index)),
		1,
		raw_data(&light.emissive),
	)

	gl.Uniform1f(gl.GetUniformLocation(shader_id, fmt.ctprintf("point_lights[{}].constant", index)), light.constant)
	gl.Uniform1f(gl.GetUniformLocation(shader_id, fmt.ctprintf("point_lights[{}].linear", index)), light.linear)
	gl.Uniform1f(gl.GetUniformLocation(shader_id, fmt.ctprintf("point_lights[{}].quadratic", index)), light.quadratic)
}

directional_light_set_uniform :: proc(light: ^DirectionalLight, shader_id: u32) {
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "directional_light.direction"), 1, raw_data(&light.direction))
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "directional_light.ambient"), 1, raw_data(&light.ambient))
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "directional_light.diffuse"), 1, raw_data(&light.diffuse))
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "directional_light.specular"), 1, raw_data(&light.specular))
}

spot_light_set_uniform :: proc(light: ^SpotLight, shader_id: u32) {
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "spot_light.position"), 1, raw_data(&light.position))
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "spot_light.direction"), 1, raw_data(&light.direction))
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "spot_light.ambient"), 1, raw_data(&light.ambient))
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "spot_light.diffuse"), 1, raw_data(&light.diffuse))
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "spot_light.specular"), 1, raw_data(&light.specular))
	gl.Uniform1f(gl.GetUniformLocation(shader_id, "spot_light.inner_cutoff"), light.inner_cutoff)
	gl.Uniform1f(gl.GetUniformLocation(shader_id, "spot_light.outer_cutoff"), light.outer_cutoff)
	gl.Uniform1f(gl.GetUniformLocation(shader_id, "spot_light.constant"), light.constant)
	gl.Uniform1f(gl.GetUniformLocation(shader_id, "spot_light.linear"), light.linear)
	gl.Uniform1f(gl.GetUniformLocation(shader_id, "spot_light.quadratic"), light.quadratic)

}
