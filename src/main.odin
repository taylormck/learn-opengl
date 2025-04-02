package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
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
            #load("../shaders/vert/pos_color_tex_tranform.vert"),
            #load("../shaders/frag/double_tex.frag"),
        ) or_else panic("Failed to load the shader")

    vertex_data: render.VertexData

    append(&vertex_data.positions, ..RECTANGLE_VERTEX_POSITIONS[:])
    append(&vertex_data.colors, ..RECTANGLE_VERTEX_COLORS[:])
    append(&vertex_data.uvs, ..RECTANGLE_TEXTURE_COORDS[:])
    indices := RECTANGLE_INDICES

    assert(len(vertex_data.positions) == len(vertex_data.colors))
    assert(len(vertex_data.positions) == len(vertex_data.uvs))

    vao, vbo, ebo: u32
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

    box_texture_ids: [2]u32
    gl.GenTextures(2, raw_data(box_texture_ids[:]))
    defer gl.DeleteTextures(2, raw_data(box_texture_ids[:]))

    wall_texture_img := prepare_texture(
        path = "textures/container.png",
        channels = 3,
        texture_number = 0,
        shader_program = shader_program,
        texture_id = box_texture_ids[0],
        gl_texture = gl.TEXTURE0,
    )
    defer image.image_free(wall_texture_img.buffer)

    face_texture_img := prepare_texture(
        path = "textures/awesomeface.png",
        channels = 4,
        texture_number = 1,
        shader_program = shader_program,
        texture_id = box_texture_ids[1],
        gl_texture = gl.TEXTURE1,
    )
    defer image.image_free(face_texture_img.buffer)

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
        gl.BindTexture(gl.TEXTURE_2D, box_texture_ids[0])

        gl.ActiveTexture(gl.TEXTURE1)
        gl.BindTexture(gl.TEXTURE_2D, box_texture_ids[1])

        gl.Uniform1f(gl.GetUniformLocation(shader_program, "time"), f32(new_time))

        translation := linalg.matrix4_translate(Vec3{0.8 * f32(math.sin(new_time)), 0, 0})
        rotation := linalg.matrix4_rotate(f32(new_time * 0.5), Vec3{0, 0, 1})
        transform := translation * rotation
        gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "transform"), 1, false, raw_data(&transform))

        gl.BindVertexArray(vao)
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

prepare_texture :: proc(
    path: cstring,
    channels, texture_number: i32,
    shader_program, texture_id, gl_texture: u32,
) -> (
    img: Texture,
) {
    gl.ActiveTexture(gl_texture)
    gl.BindTexture(gl.TEXTURE_2D, texture_id)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    if !load_texture_2d(path, &img, channels) {panic(fmt.aprintf("Failed to load texture: {}", path))}

    assert(img.channels == channels)

    format: i32
    switch channels {
    case 3:
        format = gl.RGB
    case 4:
        format = gl.RGBA
    case:
        panic(fmt.aprintf("Unsupported number of channels: {}", channels))
    }

    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        format,
        img.width,
        img.height,
        0,
        transmute(u32)format,
        gl.UNSIGNED_BYTE,
        img.buffer,
    )
    gl.GenerateMipmap(gl.TEXTURE_2D)
    gl.Uniform1i(gl.GetUniformLocation(shader_program, fmt.caprintf("texture_{}", texture_number)), texture_number)

    return img
}

load_texture_2d :: proc(path: cstring, t: ^Texture, channels: i32, flip_vertically: bool = true) -> (ok: bool) {
    if flip_vertically do image.set_flip_vertically_on_load(1)
    t.buffer = image.load(path, &t.width, &t.height, &t.channels, channels)

    return t.buffer != nil && t.channels == channels
}
