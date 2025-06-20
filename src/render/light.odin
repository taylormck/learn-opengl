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

point_light_set_uniform :: proc(light: ^PointLight, shader_id: u32, location := #caller_location) {
	shaders.set_vec3(shader_id, "point_light.position", raw_data(&light.position), caller_location = location)
	shaders.set_vec3(shader_id, "point_light.ambient", raw_data(&light.ambient), caller_location = location)
	shaders.set_vec3(shader_id, "point_light.diffuse", raw_data(&light.diffuse), caller_location = location)
	shaders.set_vec3(shader_id, "point_light.specular", raw_data(&light.specular), caller_location = location)
	shaders.set_vec3(shader_id, "point_light.emissive", raw_data(&light.emissive), caller_location = location)

	shaders.set_float(shader_id, "point_light.constant", light.constant, caller_location = location)
	shaders.set_float(shader_id, "point_light.linear", light.linear, caller_location = location)
	shaders.set_float(shader_id, "point_light.quadratic", light.quadratic, caller_location = location)
}

point_light_array_set_uniform :: proc(light: ^PointLight, shader_id: u32, index: u32, location := #caller_location) {
	shaders.set_vec3(
		shader_id,
		fmt.ctprintf("point_lights[{}].position", index),
		raw_data(&light.position),
		caller_location = location,
	)
	shaders.set_vec3(
		shader_id,
		fmt.ctprintf("point_lights[{}].ambient", index),
		raw_data(&light.ambient),
		caller_location = location,
	)
	shaders.set_vec3(
		shader_id,
		fmt.ctprintf("point_lights[{}].diffuse", index),
		raw_data(&light.diffuse),
		caller_location = location,
	)
	shaders.set_vec3(
		shader_id,
		fmt.ctprintf("point_lights[{}].specular", index),
		raw_data(&light.specular),
		caller_location = location,
	)
	shaders.set_vec3(
		shader_id,
		fmt.ctprintf("point_lights[{}].emissive", index),
		raw_data(&light.emissive),
		caller_location = location,
	)
	shaders.set_float(
		shader_id,
		fmt.ctprintf("point_lights[{}].constant", index),
		light.constant,
		caller_location = location,
	)
	shaders.set_float(
		shader_id,
		fmt.ctprintf("point_lights[{}].linear", index),
		light.linear,
		caller_location = location,
	)
	shaders.set_float(
		shader_id,
		fmt.ctprintf("point_lights[{}].quadratic", index),
		light.quadratic,
		caller_location = location,
	)
}

directional_light_set_uniform :: proc(light: ^DirectionalLight, shader_id: u32, location := #caller_location) {
	shaders.set_vec3(shader_id, "directional_light.direction", raw_data(&light.direction), caller_location = location)
	shaders.set_vec3(shader_id, "directional_light.ambient", raw_data(&light.ambient), caller_location = location)
	shaders.set_vec3(shader_id, "directional_light.diffuse", raw_data(&light.diffuse), caller_location = location)
	shaders.set_vec3(shader_id, "directional_light.specular", raw_data(&light.specular), caller_location = location)
}

spot_light_set_uniform :: proc(light: ^SpotLight, shader_id: u32, location := #caller_location) {
	shaders.set_vec3(shader_id, "spot_light.position", raw_data(&light.position), caller_location = location)
	shaders.set_vec3(shader_id, "spot_light.direction", raw_data(&light.direction), caller_location = location)
	shaders.set_vec3(shader_id, "spot_light.ambient", raw_data(&light.ambient), caller_location = location)
	shaders.set_vec3(shader_id, "spot_light.diffuse", raw_data(&light.diffuse), caller_location = location)
	shaders.set_vec3(shader_id, "spot_light.specular", raw_data(&light.specular), caller_location = location)
	shaders.set_float(shader_id, "spot_light.inner_cutoff", light.inner_cutoff, caller_location = location)
	shaders.set_float(shader_id, "spot_light.outer_cutoff", light.outer_cutoff, caller_location = location)
	shaders.set_float(shader_id, "spot_light.constant", light.constant, caller_location = location)
	shaders.set_float(shader_id, "spot_light.linear", light.linear, caller_location = location)
	shaders.set_float(shader_id, "spot_light.quadratic", light.quadratic, caller_location = location)
}
