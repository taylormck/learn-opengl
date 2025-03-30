package main

import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

WIDTH :: 800
HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

Vec3 :: [3]f32

TriangleVertexColor :: struct {
    position: Vec3,
    color:    Vec3,
}

TRIANGLE_VERTICES :: [?]f32 {
    // bottom left
    -0.5,
    -0.5,
    0,
    // ====
    // bottom right
    0.5,
    -0.5,
    0,
    // ====
    // top
    0,
    0.5,
    0,
    // ====
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

    // basic_shader_program :=
    //     gl.load_shaders_source(#load("../shaders/vert/basic.vert"), #load("../shaders/frag/basic.frag")) or_else panic(
    //         "Failed to load the shader.",
    //     )

    vertex_color_shader_program :=
        gl.load_shaders_source(
            #load("../shaders/vert/pos_and_color.vert"),
            #load("../shaders/frag/vert_color.frag"),
        ) or_else panic("Failed to load the shader")

    // vertices := RECTANGLE_VERTICES
    // indicies := RECTANGLE_INDICES
    vertices := TRIANGLE_VERTICES_COLOR

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
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 6, 0)
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 6, size_of(Vec3))
    gl.EnableVertexAttribArray(1)

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()
        process_input(window)

        gl.ClearColor(0.1, 0.2, 0.3, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(vertex_color_shader_program)
        gl.BindVertexArray(vao)
        gl.DrawArrays(gl.TRIANGLES, 0, 3)
        // gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

        gl.BindVertexArray(0)

        glfw.SwapBuffers(window)
    }
}

process_input :: proc(window: glfw.WindowHandle) {
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
        glfw.SetWindowShouldClose(window, true)
    }
}

/**
 * This function is the naive implementation of the code necessary to load the basic shader.
 * We can largely replace it with Odin's vendor:gl library helpers, but it's here for old time's sake.
 */
load_basic_shader :: proc() -> (program_id: u32, ok: bool) {
    vertex_shader_source := #load("../shaders/vert/basic.vert", cstring)
    vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vertex_shader, 1, &vertex_shader_source, nil)
    gl.CompileShader(vertex_shader)
    {
        success: i32
        gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)

        if success == 0 {
            info_log: [512]u8
            gl.GetShaderInfoLog(vertex_shader, 512, nil, raw_data(info_log[:]))
            log.errorf("ERROR::SHADER::VERTEX::COMPILATION_FAILED:\n{}", string(info_log[:]))
            return 0, false
        }
    }


    frag_shader_source := #load("../shaders/frag/basic.frag", cstring)
    frag_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(frag_shader, 1, &frag_shader_source, nil)
    gl.CompileShader(frag_shader)
    {
        success: i32
        gl.GetShaderiv(frag_shader, gl.COMPILE_STATUS, &success)

        if success == 0 {
            info_log: [512]u8
            gl.GetShaderInfoLog(frag_shader, 512, nil, raw_data(info_log[:]))
            log.errorf("ERROR::SHADER::FRAG::COMPILATION_FAILED:\n{}", string(info_log[:]))
            return 0, false
        }
    }

    program_id = gl.CreateProgram()
    gl.UseProgram(program_id)
    gl.AttachShader(program_id, vertex_shader)
    gl.AttachShader(program_id, frag_shader)
    gl.LinkProgram(program_id)

    {
        success: i32
        gl.GetProgramiv(program_id, gl.LINK_STATUS, &success)

        if success == 0 {
            info_log: [512]u8
            gl.GetProgramInfoLog(program_id, 512, nil, raw_data(info_log[:]))
            log.errorf("ERROR::SHADER::PROGRAM::LINKING_FAILED:\n{}", string(info_log[:]))
            return 0, false
        }
    }

    gl.DeleteShader(vertex_shader)
    gl.DeleteShader(frag_shader)

    return program_id, true
}
