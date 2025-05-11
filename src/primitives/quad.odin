package mesh

import "../render"
import "../types"
import gl "vendor:OpenGL"

NUM_QUAD_VERTICES :: 4

QUAD_VERTEX_POSITIONS := [NUM_QUAD_VERTICES]types.Vec3 {
    {0.5, 0.5, 0.0}, // top right
    {0.5, -0.5, 0.0}, // bottom right
    {-0.5, 0.5, 0.0}, // top left
    {-0.5, -0.5, 0.0}, // bottom left
}

QUAD_VERTEX_COLORS := [NUM_QUAD_VERTICES]types.Vec3 {
    {1, 0, 0}, // top right
    {0, 1, 0}, // bottom right
    {1, 1, 0}, // top left
    {0, 0, 1}, // bottom left
}

QUAD_VERTEX_NORMALS := [NUM_QUAD_VERTICES]types.Vec3 {
    {0, 0, 1}, // top right
    {0, 0, 1}, // bottom right
    {0, 0, 1}, // top left
    {0, 0, 1}, // bottom left
}

QUAD_TEXTURE_COORDS := [NUM_QUAD_VERTICES]types.Vec2 {
    {1, 1}, // top right
    {1, 0}, // bottom right
    {0, 1}, // top left
    {0, 0}, // bottom left
}

QUAD_INDICES := [2]types.Vec3u{{0, 1, 2}, {1, 3, 2}}

quad_vao, quad_vbo, quad_ebo: u32

quad_send_to_gpu :: proc() {
    gl.GenVertexArrays(1, &quad_vao)
    gl.GenBuffers(1, &quad_vbo)
    gl.GenBuffers(1, &quad_ebo)

    gl.BindVertexArray(quad_vao)

    positions_offset := 0
    positions_size := size_of(types.Vec3) * len(QUAD_VERTEX_POSITIONS)
    // colors_offset := positions_size
    // colors_size := size_of(types.Vec3) * len(QUAD_VERTEX_NORMALS)
    colors_offset := positions_size
    colors_size := 0
    uvs_offset := colors_offset + colors_size
    uvs_size := size_of(types.Vec2) * len(QUAD_TEXTURE_COORDS)
    normals_offset := uvs_offset + uvs_size
    normals_size := size_of(types.Vec3) + normals_offset
    total_size := positions_size + normals_size + uvs_size + normals_size
    indices := QUAD_INDICES

    gl.BindBuffer(gl.ARRAY_BUFFER, quad_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, total_size, nil, gl.STATIC_DRAW)

    gl.BufferSubData(gl.ARRAY_BUFFER, 0, positions_size, raw_data(QUAD_VERTEX_POSITIONS[:]))
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), 0)
    gl.EnableVertexAttribArray(0)

    // gl.BufferSubData(gl.ARRAY_BUFFER, colors_offset, colors_size, raw_data(QUAD_VERTEX_COLORS[:]))
    // gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), uintptr(colors_offset))
    // gl.EnableVertexAttribArray(1)

    gl.BufferSubData(gl.ARRAY_BUFFER, uvs_offset, uvs_size, raw_data(QUAD_TEXTURE_COORDS[:]))
    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(types.Vec2), uintptr(uvs_offset))
    gl.EnableVertexAttribArray(1)

    gl.BufferSubData(gl.ARRAY_BUFFER, colors_offset, colors_size, raw_data(QUAD_VERTEX_NORMALS[:]))
    gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, size_of(types.Vec3), uintptr(colors_offset))
    gl.EnableVertexAttribArray(2)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, quad_ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)
}

quad_clear_from_gpu :: proc() {
    gl.DeleteBuffers(1, &quad_vbo)
    gl.DeleteBuffers(1, &quad_ebo)
    gl.DeleteVertexArrays(1, &quad_vao)
}

quad_draw :: proc() {
    gl.BindVertexArray(quad_vao)
    defer gl.BindVertexArray(0)

    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
}
