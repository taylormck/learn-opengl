package render

import "../types"
import "core:fmt"
import "core:log"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

Texture :: struct {
	id:   u32,
	type: TextureType,
}

TextureType :: enum {
	Diffuse,
	Specular,
	Normal,
}

Image :: struct {
	width, height, channels: i32,
	buffer:                  [^]u8,
}

load_texture_2d :: proc(path: cstring, flip_vertically: bool = false) -> (img: Image, ok: bool) {
	if flip_vertically do stbi.set_flip_vertically_on_load(1)
	img.buffer = stbi.load(path, &img.width, &img.height, &img.channels, 0)

	ok = img.buffer != nil
	return
}

prepare_texture :: proc(path: cstring, texture_type: TextureType, flip_vertically: bool = false) -> (t: Texture) {
	img, img_ok := load_texture_2d(path, flip_vertically)
	if !img_ok {
		panic(fmt.aprintf("Failed to load texture: {}", path))
	}
	defer stbi.image_free(img.buffer)

	t.type = texture_type
	gl.GenTextures(1, &t.id)
	gl.BindTexture(gl.TEXTURE_2D, t.id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	format: i32 = ---
	switch img.channels {
	case 1:
		format = gl.RED
	case 2:
		format = gl.RG
	case 3:
		format = gl.RGB
	case 4:
		format = gl.RGBA
	case:
		panic(fmt.aprintf("Unsupported number of channels: {}", img.channels))
	}

	gl.TexImage2D(gl.TEXTURE_2D, 0, format, img.width, img.height, 0, transmute(u32)format, gl.UNSIGNED_BYTE, img.buffer)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	return t
}
