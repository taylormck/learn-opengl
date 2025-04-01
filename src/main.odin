package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:time"
import "render"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "vendor:stb/image"

WIDTH :: 800
HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

TARGET_FRAMERATE :: 60
TARGET_FRAME_SECONDS :: 1.0 / TARGET_FRAMERATE

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec3u :: [3]u32

NUM_TRIANGLE_VERTICES :: 3

TRIANGLE_VERTEX_POSITIONS := [NUM_TRIANGLE_VERTICES]Vec3 {
    {-0.5, -0.5, 0}, // bottom left
    {0.5, -0.5, 0}, // bottom right
    {0, 0.5, 0}, // top
}

TRIANGLE_VERTEX_COLORS := [NUM_TRIANGLE_VERTICES]Vec3 {
    {1, 0, 0}, // bottom left
    {0, 1, 0}, // bottom right
    {0, 0, 1}, // top
}

TRIANGLE_TEXTURE_COORDS := [NUM_TRIANGLE_VERTICES]Vec2 {
    {0, 0}, // bottom left
    {1, 0}, // bottom right
    {0.5, 1}, // top
}

NUM_RECTANGLE_VERTICES :: 4

RECTANGLE_VERTEX_POSITIONS := [NUM_RECTANGLE_VERTICES]Vec3 {
    {0.5, 0.5, 0.0}, // top right
    {0.5, -0.5, 0.0}, // bottom right
    {-0.5, 0.5, 0.0}, // top left
    {-0.5, -0.5, 0.0}, // bottom left
}

RECTANGLE_VERTEX_COLORS := [NUM_RECTANGLE_VERTICES]Vec3 {
    {1, 0, 0}, // top right
    {0, 1, 0}, // bottom right
    {1, 1, 0}, // top left
    {0, 0, 1}, // bottom left
}

RECTANGLE_TEXTURE_COORDS := [NUM_RECTANGLE_VERTICES]Vec2 {
    {1, 1}, // top right
    {1, 0}, // bottom right
    {0, 1}, // top left
    {0, 0}, // bottom left
}

RECTANGLE_INDICES := [2]Vec3u{{0, 1, 2}, {1, 3, 2}}

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
            #load("../shaders/vert/pos_color_tex.vert"),
            #load("../shaders/frag/double_tex.frag"),
        ) or_else panic("Failed to load the shader")

    vertex_data: render.VertexData
    // append(&vertex_data.positions, ..TRIANGLE_VERTEX_POSITIONS[:])
    // append(&vertex_data.colors, ..TRIANGLE_VERTEX_COLORS[:])
    // append(&vertex_data.uvs, ..TRIANGLE_TEXTURE_COORDS[:])

    append(&vertex_data.positions, ..RECTANGLE_VERTEX_POSITIONS[:])
    append(&vertex_data.colors, ..RECTANGLE_VERTEX_COLORS[:])
    append(&vertex_data.uvs, ..RECTANGLE_TEXTURE_COORDS[:])
    indices := RECTANGLE_INDICES

    assert(len(vertex_data.positions) == len(vertex_data.colors))
    assert(len(vertex_data.positions) == len(vertex_data.uvs))

    vao, vbo, ebo, wall_texture, face_texture: u32
    gl.GenVertexArrays(1, &vao)
    defer gl.DeleteVertexArrays(1, &vao)

    // Make sure to bind the VAO first
    gl.BindVertexArray(vao)

    gl.GenBuffers(1, &vbo)
    defer gl.DeleteBuffers(1, &vbo)

    gl.GenBuffers(1, &ebo)
    defer gl.DeleteBuffers(1, &ebo)

    positions_offset := 0
    positions_size := size_of(Vec3) * len(vertex_data.positions)
    colors_offset := positions_size
    colors_size := size_of(Vec3) * len(vertex_data.colors)
    uvs_offset := colors_offset + colors_size
    uvs_size := size_of(Vec2) * len(vertex_data.uvs)
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
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(Vec2), uintptr(uvs_offset))
    gl.EnableVertexAttribArray(2)

    gl.BufferSubData(gl.ARRAY_BUFFER, normals_offset, normals_size, raw_data(vertex_data.normals))
    gl.VertexAttribPointer(3, 3, gl.FLOAT, gl.FALSE, size_of(Vec3), uintptr(normals_offset))
    gl.EnableVertexAttribArray(3)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)


    gl.UseProgram(shader_program)

    gl.GenTextures(1, &wall_texture)
    defer gl.DeleteTextures(1, &wall_texture)

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, wall_texture)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    wall_texture_img: Texture
    if !load_texture_2d(
        "textures/container.png",
        &wall_texture_img,
        3,
    ) {panic("Failed to load the container texture.")}
    defer image.image_free(wall_texture_img.buffer)

    assert(wall_texture_img.channels == 3)

    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGB,
        wall_texture_img.width,
        wall_texture_img.height,
        0,
        gl.RGB,
        gl.UNSIGNED_BYTE,
        wall_texture_img.buffer,
    )
    gl.GenerateMipmap(gl.TEXTURE_2D)
    gl.Uniform1ui(gl.GetUniformLocation(shader_program, "texture_0"), wall_texture)

    gl.GenTextures(1, &face_texture)
    defer gl.DeleteTextures(1, &face_texture)

    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, face_texture)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    face_texture_img: Texture
    if !load_texture_2d("textures/awesomeface.png", &face_texture_img, 4) {panic("Failed to load the face texture.")}
    defer image.image_free(face_texture_img.buffer)

    assert(face_texture_img.channels == 4)

    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        face_texture_img.width,
        face_texture_img.height,
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        face_texture_img.buffer,
    )
    gl.GenerateMipmap(gl.TEXTURE_2D)
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "texture_1"), 1)

    prev_time := glfw.GetTime()

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()
        process_input(window)

        new_time := glfw.GetTime()
        delta := new_time - prev_time

        gl.ClearColor(0.1, 0.2, 0.3, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader_program)

        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, wall_texture)

        gl.ActiveTexture(gl.TEXTURE1)
        gl.BindTexture(gl.TEXTURE_2D, face_texture)

        gl.Uniform1f(gl.GetUniformLocation(shader_program, "time"), f32(new_time))

        gl.BindVertexArray(vao)
        // gl.DrawArrays(gl.TRIANGLES, 0, 3)
        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

        glfw.SwapBuffers(window)
        gl.BindVertexArray(0)
        prev_time = new_time
    }
}

process_input :: proc(window: glfw.WindowHandle) {
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
        glfw.SetWindowShouldClose(window, true)
    }
}

Texture :: struct {
    width:    i32,
    height:   i32,
    channels: i32,
    buffer:   [^]u8,
}

load_texture_2d :: proc(path: cstring, t: ^Texture, channels: i32, flip_vertically: bool = true) -> (ok: bool) {
    image.set_flip_vertically_on_load(1 if flip_vertically else 0)
    t.buffer = image.load(path, &t.width, &t.height, &t.channels, channels)

    return t.buffer != nil && t.channels == channels
}
