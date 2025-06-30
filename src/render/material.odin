package render

import "../shaders"
import "../types"

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

MaterialEntries :: enum {
	Ambient,
	Diffuse,
	Specular,
	Emissive,
	Shininess,
}

SetMaterialOptions :: bit_set[MaterialEntries]

DEFAULT_MATIERAL_OPTIONS :: SetMaterialOptions{.Ambient, .Diffuse, .Specular, .Shininess}

material_calculated_set_uniform :: proc(
	material: ^MaterialCalculated,
	shader_id: u32,
	options: SetMaterialOptions = DEFAULT_MATIERAL_OPTIONS,
) {
	if .Ambient in options do shaders.set_vec3(shader_id, "material.ambient", raw_data(&material.ambient))
	if .Diffuse in options do shaders.set_vec3(shader_id, "material.diffuse", raw_data(&material.diffuse))
	if .Specular in options do shaders.set_vec3(shader_id, "material.specular", raw_data(&material.specular))
	if .Shininess in options do shaders.set_float(shader_id, "material.shininess", material.shininess)
}

material_sampled_set_uniform :: proc(
	material: ^MaterialSampled,
	shader_id: u32,
	options: SetMaterialOptions = DEFAULT_MATIERAL_OPTIONS,
) {
	if .Diffuse in options do shaders.set_int(shader_id, "material.diffuse_0", 0)
	if .Specular in options do shaders.set_int(shader_id, "material.specular_0", 1)
	if .Emissive in options do shaders.set_int(shader_id, "material.emissive_0", 2)
	if .Shininess in options do shaders.set_float(shader_id, "material.shininess", material.shininess)
}

material_free :: proc(material: ^Material) {
	delete(material.name)
	delete(material.diffuse_map)
	delete(material.specular_map)
	delete(material.normal_map)
}
