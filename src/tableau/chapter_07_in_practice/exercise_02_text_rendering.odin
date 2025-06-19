package chapter_07_in_practice

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:log"
import "core:math/linalg"
import "core:os"
import gl "vendor:OpenGL"
import tt "vendor:stb/truetype"

@(private = "file")
FONT_PATH :: "fonts/Crimson_Text/CrimsonText-Regular.ttf"

@(private = "file")
FONT_SCALE :: 125

@(private = "file")
glyph_bitmap: [^]u8

@(private = "file")
TEXT :: "Hello, world!"

@(private = "file")
CharacterTexture :: struct {
	texture_id: u32,
	width:      i32,
	height:     i32,
	bbox_x:     f32,
	bbox_y:     f32,
	advance:    f32,
	bitmap:     [^]u8,
}

@(private = "file")
bitmap_width, bitmap_height, x0, y0: i32

@(private = "file")
glyph_textures: map[rune]CharacterTexture

@(private = "file")
CYAN :: types.Vec3{0.5, 1, 1}

@(private = "file", rodata)
STARTING_TEXT_POSITION := types.Vec2{-0.9, 0.1}

exercise_02_text_rendering := types.Tableau {
	init = proc() {
		shaders.init_shaders(.Text)
		primitives.quad_send_to_gpu()

		log.infof("Loading font {}", FONT_PATH)
		font_data := os.read_entire_file(FONT_PATH) or_else panic("Failed to load font")
		defer delete(font_data)

		log.infof("Initializing font {}", FONT_PATH)
		font: tt.fontinfo
		tt.InitFont(info = &font, data = raw_data(font_data), offset = 0)

		char_scale := tt.ScaleForPixelHeight(&font, FONT_SCALE)

		gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
		defer gl.PixelStorei(gl.UNPACK_ALIGNMENT, 4)

		log.infof("Rendering textures for each characters in the string")
		for rune in TEXT {
			if rune in glyph_textures do continue

			char_index := tt.FindGlyphIndex(&font, rune)

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

			glyph_textures[rune] = CharacterTexture {
				texture_id = texture_id,
				width      = bitmap_width,
				height     = bitmap_height,
				bbox_x     = bbox_x,
				bbox_y     = bbox_y,
				advance    = advance,
				bitmap     = glyph_bitmap,
			}
		}
	},
	draw = proc() {
		text_shader := shaders.shaders[.Text]

		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.Enable(gl.BLEND)
		defer gl.Disable(gl.BLEND)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

		gl.UseProgram(text_shader)
		color := CYAN
		shaders.set_vec3(text_shader, "color", raw_data(&color))

		window_width := f32(window.width)
		window_height := f32(window.height)

		// This transform moves the quad up so that the bottom left corner is on the origin.
		base_transform := linalg.matrix4_translate_f32({0.5, 0.5, 0.5})

		x: f32 = STARTING_TEXT_POSITION.x
		y: f32 = STARTING_TEXT_POSITION.y

		for r, i in TEXT {
			tex := glyph_textures[r]
			xpos := x + (tex.bbox_x / window_width)
			ypos := y + (tex.bbox_y / window_height)

			if tex.bitmap != nil {
				transform :=
					linalg.matrix4_translate_f32({xpos, ypos, 0}) *
					linalg.matrix4_scale_f32({f32(tex.width) / window_width, f32(tex.height) / window_height, 0}) *
					base_transform
				shaders.set_mat_4x4(text_shader, "transform", raw_data(&transform))

				gl.BindTexture(gl.TEXTURE_2D, tex.texture_id)

				primitives.quad_draw()
			}

			x += tex.advance / window_width
		}
	},
	teardown = proc() {
		log.info("Deleteing the textures for the display characters")
		for _, &texture in glyph_textures {
			gl.DeleteTextures(1, &texture.texture_id)
			tt.FreeBitmap(texture.bitmap, nil)
		}

		primitives.quad_clear_from_gpu()
	},
}
