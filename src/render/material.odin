package render

import "../shaders"
import "../types"
import gl "vendor:OpenGL"

MaterialCalculated :: struct {
	ambient, diffuse, specular: types.Vec3,
	shininess:                  f32,
}

MaterialSampled :: struct {
	diffuse, specular: u32,
	shininess:         f32,
}

Material :: struct {
	ambient, diffuse, specular, emissive:        types.Vec4,
	shininess:                                   f32,
	name, diffuse_map, normal_map, specular_map: string,
}

MaterialMap :: map[string]Material

material_calculated_set_uniform :: proc(material: ^MaterialCalculated, shader_id: u32) {
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "material.ambient"), 1, raw_data(&material.ambient))
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "material.diffuse"), 1, raw_data(&material.diffuse))
	gl.Uniform3fv(gl.GetUniformLocation(shader_id, "material.specular"), 1, raw_data(&material.specular))
	gl.Uniform1f(gl.GetUniformLocation(shader_id, "material.shininess"), material.shininess)
}

material_sampled_set_uniform :: proc(material: ^MaterialSampled, shader_id: u32) {
	shaders.set_int(shader_id, "material.diffuse_0", 0)
	shaders.set_int(shader_id, "material.specular_0", 1)
	shaders.set_int(shader_id, "material.emissive_0", 2)
	shaders.set_float(shader_id, "material.shininess", material.shininess)
}

material_free :: proc(material: ^Material) {
	delete(material.name)
	delete(material.diffuse_map)
	delete(material.specular_map)
	delete(material.normal_map)
}
