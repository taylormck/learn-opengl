package main

import "core:fmt"
import "core:log"
import "core:math"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

WIDTH :: 800
HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

Vec3 :: [3]f32

TriangleVertex :: struct {
    posotion: Vec3,
}

TriangleVertexColor :: struct {
    position: Vec3,
    color:    Vec3,
}

TRIANGLE_VERTICES :: [?]Vec3 {
    {-0.5, -0.5, 0}, // bottom left
    {0.5, -0.5, 0}, // bottom right
    {0, 0.5, 0}, // top
}

TRIANGLE_VERTICES_COLOR :: [?]TriangleVertexColor {
    TriangleVertexColor{position = {-0.5, -0.5, 0}, color = {1, 0, 0}},
    TriangleVertexColor{position = {0.5, -0.5, 0}, color = {0, 1, 0}},
    TriangleVertexColor{position = {0, 0.5, 0}, color = {0, 0, 1}},
}

RECTANGLE_VERTICES :: [?]f32 {
    // top right
    0.5,
    0.5,
    0.0,
    // ====
    // bottom right
    0.5,
    -0.5,
    0.0,
    // ====
    // bottom left
    -0.5,
    -0.5,
    0.0,
    // ====
    // top left
    -0.5,
    0.5,
    0.0,
    // ====
}

RECTANGLE_INDICES :: [?]i32 {
    // first trinagle
    0,
    1,
    3,
    // ====
    // second triangle
    1,
    2,
    3,
    // ====
}

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
            #load("../shaders/vert/basic_palette.vert"),
            #load("../shaders/frag/vert_color.frag"),
        ) or_else panic("Failed to load the shader")

    vertices := TRIANGLE_VERTICES

    vao, vbo, ebo: u32
    gl.GenVertexArrays(1, &vao)
    defer gl.DeleteVertexArrays(1, &vao)

    gl.GenBuffers(1, &vbo)
    defer gl.DeleteBuffers(1, &vbo)

    // gl.GenBuffers(1, &ebo)
    // defer gl.DeleteBuffers(1, &ebo)

    // Make sure to bind the VAO first
    gl.BindVertexArray(vao)

    // Then pass data to the GPU, since that takes time
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

    // gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    // gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indicies), &indicies, gl.STATIC_DRAW)

    // Finally, set the vertex attributes
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(TriangleVertex), 0)
    gl.EnableVertexAttribArray(0)

    // gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 6, size_of(Vec3))
    // gl.EnableVertexAttribArray(1)

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
