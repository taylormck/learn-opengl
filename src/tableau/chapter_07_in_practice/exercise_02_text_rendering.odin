package chapter_07_in_practice

import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "core:log"
import "core:os"
import gl "vendor:OpenGL"
import tt "vendor:stb/truetype"

@(private = "file")
FONT_PATH :: "fonts/Crimson_Text/CrimsonText-Regular.ttf"

@(private = "file")
FONT_SCALE :: 100

@(private = "file")
glyph_bitmap: [^]u8

@(private = "file")
CHARACTER :: '@'

@(private = "file")
bitmap_width, bitmap_height, x0, y0: i32

@(private = "file")
glyph_texture := render.Texture {
	type = .Diffuse,
}

exercise_02_text_rendering := types.Tableau {
	init = proc() {
		shaders.init_shaders(.Text)
		primitives.quad_send_to_gpu()

		log.infof("Loading font {}", FONT_PATH)
		font_data := os.read_entire_file(FONT_PATH) or_else panic("Failed to load font")

		log.infof("Initializing font {}", FONT_PATH)
		font: tt.fontinfo
		tt.InitFont(info = &font, data = raw_data(font_data), offset = 0)

		char_index := tt.FindGlyphIndex(&font, CHARACTER)

		glyph_bitmap = tt.GetGlyphBitmap(
			info = &font,
			scale_x = 0,
			scale_y = tt.ScaleForPixelHeight(&font, FONT_SCALE),
			glyph = char_index,
			width = &bitmap_width,
			height = &bitmap_height,
			xoff = &x0,
			yoff = &y0,
		)

		gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)

		gl.GenTextures(1, &glyph_texture.id)
		gl.BindTexture(gl.TEXTURE_2D, glyph_texture.id)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, bitmap_width, bitmap_height, 0, gl.RED, gl.UNSIGNED_BYTE, glyph_bitmap)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		text_shader := shaders.shaders[.Text]


		{
			gl.Enable(gl.BLEND)
			defer gl.Disable(gl.BLEND)

			gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

			gl.UseProgram(text_shader)
			primitives.quad_draw()
		}
	},
	teardown = proc() {
		gl.DeleteTextures(1, &glyph_texture.id)
		gl.PixelStorei(gl.UNPACK_ALIGNMENT, 4)
		tt.FreeBitmap(glyph_bitmap, nil)
		primitives.quad_clear_from_gpu()
	},
}
