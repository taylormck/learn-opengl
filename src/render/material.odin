package render

import "../types"
import gl "vendor:OpenGL"

Material :: struct {
    ambient, diffuse, specular: types.Vec3,
    shininess:                  f32,
}

material_set_uniform :: proc(material: ^Material, shader_id: u32) {
    gl.Uniform3fv(gl.GetUniformLocation(shader_id, "material.ambient"), 1, raw_data(&material.ambient))
    gl.Uniform3fv(gl.GetUniformLocation(shader_id, "material.diffuse"), 1, raw_data(&material.diffuse))
    gl.Uniform3fv(gl.GetUniformLocation(shader_id, "material.specular"), 1, raw_data(&material.specular))
    gl.Uniform1f(gl.GetUniformLocation(shader_id, "material.shininess"), material.shininess)
}
