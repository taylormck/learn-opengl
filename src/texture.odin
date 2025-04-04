package main

import "core:fmt"
import "render"
import "types"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "vendor:stb/image"


Texture :: struct {
    width, height, channels: i32,
    buffer:                  [^]u8,
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
