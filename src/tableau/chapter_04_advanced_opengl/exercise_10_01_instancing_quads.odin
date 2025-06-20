package chapter_04_advanced_opengl

import "../../input"
import "../../primitives"
import "../../render"
import "../../shaders"
import "../../types"
import "../../window"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

@(private = "file")
background_color := types.Vec3{0.1, 0.1, 0.1}

@(private = "file")
instanced_rect_offset_vbo: u32

@(private = "file")
NUM_INSTANCES :: 100

@(private = "file")
instanced_rect_translations: [NUM_INSTANCES]types.Vec2

@(private = "file")
OFFSET :: 0.1

exercise_10_01_instancing_quads :: types.Tableau {
	init = proc() {
		primitives.quad_send_to_gpu()
		shaders.init_shaders(.InstancedRect)

		index := 0
		for y := -10; y < 10; y += 2 {
			for x := -10; x < 10; x += 2 {
				translation := &instanced_rect_translations[index]
				translation.x = f32(x) / 10.0 + OFFSET
				translation.y = f32(y) / 10.0 + OFFSET
				index += 1
			}
		}

		gl.GenBuffers(1, &instanced_rect_offset_vbo)
		gl.BindBuffer(gl.ARRAY_BUFFER, instanced_rect_offset_vbo)
		gl.BufferData(gl.ARRAY_BUFFER, size_of(instanced_rect_translations), &instanced_rect_translations, gl.STATIC_DRAW)
	},
	update = proc(delta: f64) {},
	draw = proc() {
		gl.ClearColor(background_color.x, background_color.y, background_color.z, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.Disable(gl.DEPTH_TEST)

		instanced_rect_shader := shaders.shaders[.InstancedRect]

		gl.UseProgram(instanced_rect_shader)
		primitives.quad_draw_instanced(NUM_INSTANCES, instanced_rect_offset_vbo)
	},
	teardown = proc() {
		primitives.quad_clear_from_gpu()
	},
}
