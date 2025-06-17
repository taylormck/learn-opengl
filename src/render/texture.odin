package render

import "../types"
import "core:fmt"
import "core:log"
import "core:slice"
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
	Emissive,
	Displacement,
	Metallic,
	Roughness,
	AO,
}

Image :: struct {
	width, height, channels: i32,
	buffer:                  [^]u8,
}

HDRImage :: struct {
	width, height, channels: i32,
	buffer:                  [^]f32,
}

load_texture_2d :: proc(
	path: cstring,
	desired_channels: i32 = 0,
	flip_vertically: bool = false,
) -> (
	img: Image,
	ok: bool,
) {
	stbi.set_flip_vertically_on_load(1 if flip_vertically else 0)
	img.buffer = stbi.load(path, &img.width, &img.height, &img.channels, desired_channels)

	ok = img.buffer != nil
	return
}

prepare_texture :: proc(
	path: cstring,
	texture_type: TextureType,
	flip_vertically: bool = false,
	gamma_correction: bool = false,
	desired_channels: i32 = 0,
	location := #caller_location,
) -> (
	t: Texture,
) {
	img, img_ok := load_texture_2d(path, desired_channels, flip_vertically)
	if !img_ok do fmt.panicf("Failed to load texture: {}", path)
	defer stbi.image_free(img.buffer)

	num_channels := img.channels if desired_channels == 0 else desired_channels

	t.type = texture_type
	gl.GenTextures(1, &t.id)
	gl.BindTexture(gl.TEXTURE_2D, t.id)

	data_format: u32 = ---
	internal_format: i32 = ---
	switch num_channels {
	case 1:
		data_format = gl.RED
		internal_format = gl.RED
	case 2:
		data_format = gl.RG
		internal_format = gl.RG
	case 3:
		data_format = gl.RGB
		internal_format = gl.SRGB if gamma_correction else gl.RGB
	case 4:
		data_format = gl.RGBA
		internal_format = gl.SRGB_ALPHA if gamma_correction else gl.RGBA
	case:
		fmt.panicf("Unsupported number of channels: {}", num_channels)
	}

	log.infof(
		"Generating texture for image {}: gamma correction: {}, width: {}, height: {}, channels: {}",
		path,
		gamma_correction,
		img.width,
		img.height,
		img.channels,
		location = location,
	)

	gl.TexImage2D(gl.TEXTURE_2D, 0, internal_format, img.width, img.height, 0, data_format, gl.UNSIGNED_BYTE, img.buffer)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	return t
}

prepare_hdr_texture :: proc(
	path: cstring,
	texture_type: TextureType,
	flip_vertically: bool = false,
	gamma_correction: bool = false,
	desired_channels: i32 = 0,
	location := #caller_location,
) -> (
	t: Texture,
) {
	img: HDRImage

	stbi.set_flip_vertically_on_load(1 if flip_vertically else 0)
	img.buffer = stbi.loadf(path, &img.width, &img.height, &img.channels, desired_channels)
	fmt.ensuref(img.buffer != nil, "Failed to load HDR texture: {}", path, loc = location)

	defer stbi.image_free(img.buffer)

	t.type = texture_type
	gl.GenTextures(1, &t.id)
	gl.BindTexture(gl.TEXTURE_2D, t.id)

	log.infof(
		"Generating HDR texture for image {}: gamma correction: {}, width: {}, height: {}, channels: {}",
		path,
		gamma_correction,
		img.width,
		img.height,
		img.channels,
		location = location,
	)

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB16F, img.width, img.height, 0, gl.RGB, gl.FLOAT, img.buffer)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	return t
}
