package render

import "../types"
import gl "vendor:OpenGL"

Light :: struct {
    position, ambient, diffuse, specular: types.Vec3,
}

light_set_uniform :: proc(light: ^Light, shader_id: u32) {
    gl.Uniform3fv(gl.GetUniformLocation(shader_id, "light.position"), 1, raw_data(&light.position))
    gl.Uniform3fv(gl.GetUniformLocation(shader_id, "light.ambient"), 1, raw_data(&light.ambient))
    gl.Uniform3fv(gl.GetUniformLocation(shader_id, "light.diffuse"), 1, raw_data(&light.diffuse))
    gl.Uniform3fv(gl.GetUniformLocation(shader_id, "light.specular"), 1, raw_data(&light.specular))
}
