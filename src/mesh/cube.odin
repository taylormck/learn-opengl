package mesh

import "../render"
import "../types"
import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"

NUM_CUBE_VERTICES :: 36

CubeVertex :: struct {
    position: types.Vec3,
    uv:       types.Vec2,
}

CUBE_VERTICES :: [?]CubeVertex {
    {position = {-0.5, -0.5, -0.5}, uv = {0.0, 0.0}},
    {position = {0.5, -0.5, -0.5}, uv = {1.0, 0.0}},
    {position = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}},
    {position = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}},
    {position = {-0.5, 0.5, -0.5}, uv = {0.0, 1.0}},
    {position = {-0.5, -0.5, -0.5}, uv = {0.0, 0.0}},
    // ====
    {position = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}},
    {position = {0.5, -0.5, 0.5}, uv = {1.0, 0.0}},
    {position = {0.5, 0.5, 0.5}, uv = {1.0, 1.0}},
    {position = {0.5, 0.5, 0.5}, uv = {1.0, 1.0}},
    {position = {-0.5, 0.5, 0.5}, uv = {0.0, 1.0}},
    {position = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}},
    // ====
    {position = {-0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
    {position = {-0.5, 0.5, -0.5}, uv = {1.0, 1.0}},
    {position = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
    {position = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
    {position = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}},
    {position = {-0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
    // ====
    {position = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
    {position = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}},
    {position = {0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
    {position = {0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
    {position = {0.5, -0.5, 0.5}, uv = {0.0, 0.0}},
    {position = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
    // ====
    {position = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
    {position = {0.5, -0.5, -0.5}, uv = {1.0, 1.0}},
    {position = {0.5, -0.5, 0.5}, uv = {1.0, 0.0}},
    {position = {0.5, -0.5, 0.5}, uv = {1.0, 0.0}},
    {position = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}},
    {position = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
    // ====
    {position = {-0.5, 0.5, -0.5}, uv = {0.0, 1.0}},
    {position = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}},
    {position = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
    {position = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
    {position = {-0.5, 0.5, 0.5}, uv = {0.0, 0.0}},
    {position = {-0.5, 0.5, -0.5}, uv = {0.0, 1.0}},
}

cube_send_to_gpu :: proc(vao, vbo: u32) {
    gl.BindVertexArray(vao)
    vertex_data := CUBE_VERTICES

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(CubeVertex) * len(vertex_data), &vertex_data, gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(CubeVertex), offset_of(CubeVertex, position))
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(CubeVertex), offset_of(CubeVertex, uv))
    gl.EnableVertexAttribArray(1)
}

cube_draw :: proc(vao: u32) {
    gl.DrawArrays(gl.TRIANGLES, 0, 36)
}
