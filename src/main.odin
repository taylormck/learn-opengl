package main

import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

WIDTH :: 800
HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

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
        }
    }

    shader_program := gl.CreateProgram()
    gl.UseProgram(shader_program)
    gl.AttachShader(shader_program, vertex_shader)
    gl.AttachShader(shader_program, frag_shader)
    gl.LinkProgram(shader_program)

    {
        success: i32
        gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)

        if success == 0 {
            info_log: [512]u8
            gl.GetProgramInfoLog(shader_program, 512, nil, raw_data(info_log[:]))
            log.errorf("ERROR::SHADER::PROGRAM::LINKING_FAILED:\n{}", string(info_log[:]))
        }
    }

    gl.DeleteShader(vertex_shader)
    gl.DeleteShader(frag_shader)

    // Define the triangle
    vertices := [?]f32{-0.5, -0.5, 0, 0.5, -0.5, 0, 0, 0.5, 0}

    vbo, vao: u32
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)

    // Make sure to bind the VAO first
    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 3, 0)
    gl.EnableVertexAttribArray(0)

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()
        process_input(window)

        gl.ClearColor(0.1, 0.2, 0.3, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader_program)
        gl.BindVertexArray(vao)
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        glfw.SwapBuffers(window)
    }
}

process_input :: proc(window: glfw.WindowHandle) {
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
        glfw.SetWindowShouldClose(window, true)
    }
}
