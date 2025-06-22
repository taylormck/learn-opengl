package noise

import "core:log"
import "core:math/rand"

NOISE_WIDTH :: 256
NOISE_HEIGHT :: 256
NOISE_DEPTH :: 256
NOISE_LENGTH :: NOISE_WIDTH * NOISE_HEIGHT * NOISE_DEPTH

generate_noise :: proc() -> []f64 {
	noise := make([]f64, NOISE_LENGTH)

	for x in 0 ..< NOISE_WIDTH {
		for y in 0 ..< NOISE_HEIGHT {
			for z in 0 ..< NOISE_DEPTH {
				index := get_noise_index(x, y, z)
				noise[index] = rand.float64()
			}
		}
	}

	return noise
}

fill_data_array_bytes :: proc(noise: []f64, data: []u8, zoom: int = 1) {
	ensure(len(noise) == NOISE_LENGTH, "provided noise has incorrect size")
	ensure(len(data) == NOISE_LENGTH * 4, "provided data array has incorrect size")

	for x in 0 ..< NOISE_WIDTH {
		for y in 0 ..< NOISE_HEIGHT {
			for z in 0 ..< NOISE_DEPTH {
				noise_index := get_noise_index(x / zoom, y / zoom, z / zoom)
				noise_value := u8(noise[noise_index] * 255)

				data_start_index := get_noise_index(x, y, z) * 4
				for data_index in data_start_index ..< data_start_index + 3 {
					data[data_index] = noise_value
				}
				data[data_start_index + 3] = 255
			}
		}
	}
}

get_noise_index :: proc(i, j, k: int) -> int {
	ensure(i < NOISE_WIDTH, "noise index out of bounds")
	ensure(j < NOISE_HEIGHT, "noise index out of bounds")
	ensure(k < NOISE_DEPTH, "noise index out of bounds")

	return i * NOISE_WIDTH * NOISE_HEIGHT + j * NOISE_WIDTH + k
}
