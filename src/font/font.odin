package font

import "../primitives"
import "../shaders"
import "../types"
import "../utils"
import "../window"
import "core:log"
import "core:math/linalg"
import gl "vendor:OpenGL"
import tt "vendor:stb/truetype"

Font :: struct {
	name:           string,
	glyph_textures: map[rune]CharacterTexture,
	scale:          f32,
}

CharacterTexture :: struct {
	texture_id: u32,
	width:      i32,
	height:     i32,
	bbox_x:     f32,
	bbox_y:     f32,
	advance:    f32,
	bitmap:     [^]u8,
}

DRAWABLE_ASCII_RANGE_START :: 32
DRAWABLE_ASCII_RANGE_END :: 32 + 95

DEFAULT_MARGIN :: types.Vec2{12, 12}

font_init :: proc(name: string, font_data: []u8, font_scale: f32) -> (result: Font) {
	font: tt.fontinfo
	tt.InitFont(info = &font, data = raw_data(font_data), offset = 0)

	result.name = name
	result.scale = font_scale
	char_scale := tt.ScaleForPixelHeight(&font, result.scale)

	gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
	defer gl.PixelStorei(gl.UNPACK_ALIGNMENT, 4)

	log.infof("Rendering textures for each characters in the string")
	result.glyph_textures = make(map[rune]CharacterTexture)

	for i in DRAWABLE_ASCII_RANGE_START ..< DRAWABLE_ASCII_RANGE_END {
		r := rune(i)
		if r in result.glyph_textures do continue

		char_index := tt.FindGlyphIndex(&font, r)

		bitmap_width, bitmap_height, x0, y0: i32
		glyph_bitmap := tt.GetGlyphBitmap(
			info = &font,
			scale_x = 0,
			scale_y = char_scale,
			glyph = char_index,
			width = &bitmap_width,
			height = &bitmap_height,
			xoff = &x0,
			yoff = &y0,
		)

		box1, box2, box3, box4: i32
		tt.GetGlyphBox(&font, char_index, &box1, &box2, &box3, &box4)

		raw_advance, raw_l_bearing: i32
		tt.GetGlyphHMetrics(&font, char_index, &raw_advance, &raw_l_bearing)

		bbox_x := char_scale * f32(box1)
		bbox_y := char_scale * f32(box2)
		advance := char_scale * f32(raw_advance)
		l_bearing := char_scale * f32(raw_l_bearing)

		texture_id: u32

		gl.GenTextures(1, &texture_id)
		gl.BindTexture(gl.TEXTURE_2D, texture_id)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, bitmap_width, bitmap_height, 0, gl.RED, gl.UNSIGNED_BYTE, glyph_bitmap)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

		result.glyph_textures[r] = CharacterTexture {
			texture_id = texture_id,
			width      = bitmap_width,
			height     = bitmap_height,
			bbox_x     = bbox_x,
			bbox_y     = bbox_y,
			advance    = advance,
			bitmap     = glyph_bitmap,
		}
	}

	shaders.init_shaders(.Text, .TransformUniformColor)

	utils.print_gl_errors()

	return result
}

font_deinit :: proc(font: ^Font) {
	log.infof("Deleteing the {}:{} font.", font.name, font.scale)

	for _, &texture in font.glyph_textures {
		gl.DeleteTextures(1, &texture.texture_id)
		tt.FreeBitmap(texture.bitmap, nil)
	}
	utils.print_gl_errors()

	delete(font.glyph_textures)
}

font_write :: proc(font: ^Font, text: string, starting_position: types.Vec2, color: types.Vec3) {
	// Copy color to make it referenceable
	color := color
	starting_position := starting_position

	gl.Enable(gl.BLEND)
	defer gl.Disable(gl.BLEND)

	gl.Disable(gl.DEPTH_TEST)

	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	text_size := get_text_size(font, text)
	draw_text_box(font, starting_position, text_size)

	text_shader := shaders.shaders[.Text]
	gl.UseProgram(text_shader)
	shaders.set_vec3(text_shader, "color", raw_data(&color))

	window_width := f32(window.width)
	window_height := f32(window.height)

	// This transform moves the quad up so that the bottom left corner is on the origin.
	base_transform := linalg.matrix4_translate_f32({0.5, 0.5, 0.5})

	margin := DEFAULT_MARGIN / types.Vec2{window_width, -window_height}
	starting_position += margin

	x: f32 = starting_position.x
	y: f32 = starting_position.y

	gl.ActiveTexture(gl.TEXTURE0)

	for r in text {
		tex := font.glyph_textures[r]
		xpos := x + (tex.bbox_x / window_width)
		ypos := y + (tex.bbox_y / window_height)

		if tex.bitmap != nil {
			transform :=
				linalg.matrix4_translate_f32({xpos, ypos, 0}) *
				linalg.matrix4_scale_f32({f32(tex.width) / window_width, f32(tex.height) / window_height, 0}) *
				base_transform
			shaders.set_mat_4x4(text_shader, "transform", raw_data(&transform))
			utils.print_gl_errors()

			gl.BindTexture(gl.TEXTURE_2D, tex.texture_id)
			utils.print_gl_errors()

			primitives.quad_draw()
			utils.print_gl_errors()
		}

		x += tex.advance / window_width
	}

	utils.print_gl_errors()
}

get_text_size :: proc(font: ^Font, text: string) -> types.Vec3 {
	// window_width := f32(window.width)
	window_height := f32(window.height)
	x: f32 = 0
	descender_height: f32 = 0
	line_height: i32 = 0

	for r in text {
		tex := font.glyph_textures[r]
		x += tex.advance

		// bbox_y is usually negative, as it goes from the top to the bottom
		descender_height = max(descender_height, abs(tex.bbox_y))
		line_height = max(line_height, tex.height)
	}

	return {x, f32(line_height) + descender_height, descender_height}
}

draw_text_box :: proc(font: ^Font, starting_position: types.Vec2, size: types.Vec3) {
	starting_position := starting_position
	size := size

	window_width := f32(window.width)
	window_height := f32(window.height)

	box_shader := shaders.shaders[.TransformUniformColor]
	gl.UseProgram(box_shader)

	margin := DEFAULT_MARGIN
	size += margin.xyy * 2

	color := types.Vec4{0, 0, 0, 0.5}

	// This transform moves the quad up so that the bottom left corner is on the origin.
	base_transform := linalg.matrix4_translate_f32({0.5, 0.5, 0.5})

	y_offset := size.z / window_height

	transform :=
		linalg.matrix4_translate_f32({starting_position.x, starting_position.y - y_offset, 0}) *
		linalg.matrix4_scale_f32({size.x / window_width, size.y / window_height, 0}) *
		base_transform

	shaders.set_mat_4x4(box_shader, "transform", raw_data(&transform))
	shaders.set_vec4(box_shader, "our_color", raw_data(&color))

	primitives.quad_draw()
	utils.print_gl_errors()
}
