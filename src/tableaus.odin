package main

import "tableau/chapter_01_getting_started"
import "types"

Tablueas :: enum {
	Chapter_01_01_hellow_window,
	Chapter_01_02_hellow_window_clear,
	Chapter_02_01_hello_triangle,
	Chapter_02_02_hello_triangle_indexed,
	Chapter_02_02_hello_triangle_indexed_wireframe,
	Chapter_02_03_hello_triangle_exercise_01,
	Chapter_02_04_hello_triangle_exercise_02,
	Chapter_02_05_hello_triangle_exercise_03,
	Chapter_03_01_shaders_uniform,
	Chapter_03_02_shaders_interpolation,
}

tableaus := [Tablueas]types.Tableau {
	.Chapter_01_01_hellow_window                    = chapter_01_getting_started.exercise_01_01_hello_window,
	.Chapter_01_02_hellow_window_clear              = chapter_01_getting_started.exercise_01_02_hello_window_clear,
	.Chapter_02_01_hello_triangle                   = chapter_01_getting_started.exercise_02_01_hello_triangle,
	.Chapter_02_02_hello_triangle_indexed           = chapter_01_getting_started.exercise_02_02_hello_triangle_indexed,
	.Chapter_02_02_hello_triangle_indexed_wireframe = chapter_01_getting_started.exercise_02_02_hello_triangle_indexed_wireframe,
	.Chapter_02_03_hello_triangle_exercise_01       = chapter_01_getting_started.exercise_02_03_hello_triangle_exercise_01,
	.Chapter_02_04_hello_triangle_exercise_02       = chapter_01_getting_started.exercise_02_04_hello_triangle_exercise_02,
	.Chapter_02_05_hello_triangle_exercise_03       = chapter_01_getting_started.exercise_02_05_hello_triangle_exercise_03,
	.Chapter_03_01_shaders_uniform                  = chapter_01_getting_started.exercise_03_01_shaders_uniform,
	.Chapter_03_02_shaders_interpolation            = chapter_01_getting_started.exercise_03_02_shaders_interpolation,
}
