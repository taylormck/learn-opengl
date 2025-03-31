package main

import "core:fmt"
import "core:image"
import "core:log"
import "core:math"
import "render"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

WIDTH :: 800
HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec3u :: [3]u32

TRIANGLE_VERTEX_POSITIONS := [?]Vec3 {
    {-0.5, -0.5, 0}, // bottom left
    {0.5, -0.5, 0}, // bottom right
    {0, 0.5, 0}, // top
}

TRIANGLE_VERTEX_COLORS := [?]Vec3 {
    {1, 0, 0}, // bottom left
    {0, 1, 0}, // bottom right
    {0, 0, 1}, // top
}

RECTANGLE_VERTICES := [?]Vec3 {
    {0.5, 0.5, 0.0}, // top right
    {0.5, -0.5, 0.0}, // bottom right
    {-0.5, -0.5, 0.0}, // bottom left
    {-0.5, 0.5, 0.0}, // top left
}

RECTANGLE_INDICES := [?]Vec3u{{0, 1, 3}, {1, 2, 3}}

main :: proc() {
    context.logger = log.create_console_logger()
    defer log.destroy_console_logger(context.logger)

    if !bool(glfw.Init()) {
        panic("GLFW failed to init.")
    }
    defer glfw.Terminate()

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)

    window := glfw.CreateWindow(WIDTH, HEIGHT, "Hello", nil, nil)
    defer glfw.DestroyWindow(window)

    if window == nil {
        panic("GLFW failed to open the window.")
    }

    glfw.MakeContextCurrent(window)
    gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
    gl.Viewport(0, 0, WIDTH, HEIGHT)

    shader_program :=
        gl.load_shaders_source(
            #load("../shaders/vert/pos_and_color.vert"),
            #load("../shaders/frag/vert_color.frag"),
        ) or_else panic("Failed to load the shader")

    vertex_data: render.VertexData
    append(&vertex_data.positions, ..TRIANGLE_VERTEX_POSITIONS[:])
    append(&vertex_data.colors, ..TRIANGLE_VERTEX_COLORS[:])

    assert(len(vertex_data.positions) == len(vertex_data.colors))

    vao, vbo, ebo: u32
    gl.GenVertexArrays(1, &vao)
    defer gl.DeleteVertexArrays(1, &vao)

    gl.GenBuffers(1, &vbo)
    defer gl.DeleteBuffers(1, &vbo)

    // gl.GenBuffers(1, &ebo)
    // defer gl.DeleteBuffers(1, &ebo)

    // Make sure to bind the VAO first
    gl.BindVertexArray(vao)

    positions_offset := 0
    positions_size := size_of(Vec3) * len(vertex_data.positions)
    colors_offset := positions_size
    colors_size := size_of(Vec3) * len(vertex_data.colors)
    uvs_offset := colors_offset + colors_size
    uvs_size := size_of(Vec2) + len(vertex_data.uvs)
    normals_offset := uvs_offset + uvs_size
    normals_size := size_of(Vec3) + normals_offset
    total_size := positions_size + colors_size + uvs_size + normals_size

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, total_size, nil, gl.STATIC_DRAW)

    gl.BufferSubData(gl.ARRAY_BUFFER, 0, positions_size, raw_data(vertex_data.positions))
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vec3), 0)
    gl.EnableVertexAttribArray(0)

    gl.BufferSubData(gl.ARRAY_BUFFER, colors_offset, colors_size, raw_data(vertex_data.colors))
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vec3), uintptr(colors_offset))
    gl.EnableVertexAttribArray(1)

    gl.BufferSubData(gl.ARRAY_BUFFER, uvs_offset, uvs_size, raw_data(vertex_data.uvs))
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(Vec3), uintptr(uvs_offset))
    gl.EnableVertexAttribArray(2)

    gl.BufferSubData(gl.ARRAY_BUFFER, normals_offset, normals_size, raw_data(vertex_data.normals))
    gl.VertexAttribPointer(3, 3, gl.FLOAT, gl.FALSE, size_of(Vec3), uintptr(normals_offset))
    gl.EnableVertexAttribArray(3)

    // gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    // gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indicies), &indicies, gl.STATIC_DRAW)

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()
        process_input(window)

        time := f32(glfw.GetTime())

        gl.ClearColor(0.1, 0.2, 0.3, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader_program)
        gl.BindVertexArray(vao)

        gl.Uniform1f(gl.GetUniformLocation(shader_program, "time"), time)

        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        glfw.SwapBuffers(window)
        gl.BindVertexArray(0)
    }
}

process_input :: proc(window: glfw.WindowHandle) {
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
        glfw.SetWindowShouldClose(window, true)
    }
}

get_palette :: proc(t: f32, a, b, c, d: Vec3) -> Vec3 {
    partial_color := math.TAU * (c * t + d)
    partial_color = {math.cos(partial_color.x), math.cos(partial_color.y), math.cos(partial_color.z)}

    return a + b * partial_color
}

get_my_palette :: proc(t: f32) -> Vec3 {
    a := Vec3{0.5, 0.5, 0.5}
    b := Vec3{0.5, 0.5, 0.5}
    c := Vec3{1.0, 1.0, 1.0}
    d := Vec3{0.0, 0.10, 0.20}

    return get_palette(t, a, b, c, d)
}
