package chapter_07_in_practice

import "../../font"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../utils"
import "../../window"
import "core:log"
import "core:math/linalg"
import "core:os"
import gl "vendor:OpenGL"
import tt "vendor:stb/truetype"

@(private = "file")
FONT_PATH :: "../../../fonts/Crimson_Text/CrimsonText-Regular.ttf"

@(private = "file")
FONT_SCALE :: 150

@(private = "file")
glyph_bitmap: [^]u8

@(private = "file")
TEXT :: "Hello, world!"

@(private = "file")
CYAN :: types.Vec3{0.5, 1, 1}

@(private = "file", rodata)
STARTING_TEXT_POSITION := types.Vec2{-0.9, 0.1}

@(private = "file")
current_font: font.Font

exercise_02_text_rendering :: types.Tableau {
	init = proc() {
		font_data := #load(FONT_PATH)
		current_font = font.font_init("CrimsonText", font_data, FONT_SCALE)
	},
	draw = proc() {
		gl.ClearColor(0.2, 0.3, 0.3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		font.font_write(&current_font, TEXT, STARTING_TEXT_POSITION, CYAN)
	},
	teardown = proc() {
		font.font_deinit(&current_font)
	},
}
