package render

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
    ambient, diffuse, specular, emmisive:        types.Vec4,
    shininess:                                   f32,
    // NOTE: These are strings representing the relative paths to the files.
    // We may want to change these to be the IDs on the GPU, or keys in a map.
    name, diffuse_map, normal_map, specular_map: string,
}

material_calculated_set_uniform :: proc(material: ^MaterialCalculated, shader_id: u32) {
    gl.Uniform3fv(gl.GetUniformLocation(shader_id, "material.ambient"), 1, raw_data(&material.ambient))
    gl.Uniform3fv(gl.GetUniformLocation(shader_id, "material.diffuse"), 1, raw_data(&material.diffuse))
    gl.Uniform3fv(gl.GetUniformLocation(shader_id, "material.specular"), 1, raw_data(&material.specular))
    gl.Uniform1f(gl.GetUniformLocation(shader_id, "material.shininess"), material.shininess)
}

material_sampled_set_uniform :: proc(material: ^MaterialSampled, shader_id: u32) {
    gl.Uniform1i(gl.GetUniformLocation(shader_id, "material.diffuse"), 0)
    gl.Uniform1i(gl.GetUniformLocation(shader_id, "material.specular"), 1)
    gl.Uniform1f(gl.GetUniformLocation(shader_id, "material.shininess"), material.shininess)
}
