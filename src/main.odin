package main

import "core:fmt"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

WIDTH :: 480
HEIGHT :: 360

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

main :: proc() {
    if !bool(glfw.Init()) {
        panic("GLFW failed to init.")
    }
    defer glfw.Terminate()

    window := glfw.CreateWindow(WIDTH, HEIGHT, "Hello", nil, nil)
    defer glfw.DestroyWindow(window)

    if window == nil {
        panic("GLFW failed to open the window.")
    }

    glfw.MakeContextCurrent(window)
    gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()

        gl.ClearColor(0.1, 0.2, 0.3, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        glfw.SwapBuffers(window)
    }
}
