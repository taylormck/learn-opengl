package noise

import "core:log"
import "core:math/linalg"
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

fill_data_array_bytes_smooth :: proc(noise: []f64, data: []u8, zoom: f64 = 1) {
	ensure(len(noise) == NOISE_LENGTH, "provided noise has incorrect size")
	ensure(len(data) == NOISE_LENGTH * 4, "provided data array has incorrect size")

	for x in 0 ..< NOISE_WIDTH {
		for y in 0 ..< NOISE_HEIGHT {
			for z in 0 ..< NOISE_DEPTH {
				x_zoom := f64(x) / zoom
				y_zoom := f64(y) / zoom
				z_zoom := f64(z) / zoom

				noise_index := get_noise_index(int(x_zoom), int(y_zoom), int(z_zoom))
				noise_value := u8(get_smooth_noise(noise, zoom, x_zoom, y_zoom, z_zoom) * 255)

				data_start_index := get_noise_index(x, y, z) * 4
				for data_index in data_start_index ..< data_start_index + 3 {
					data[data_index] = noise_value
				}
				data[data_start_index + 3] = 255
			}
		}
	}
}

get_smooth_noise :: proc(noise: []f64, zoom, x, y, z: f64) -> f64 {
	ensure(len(noise) == NOISE_LENGTH, "provided noise has incorrect size")
	ensure(x < NOISE_WIDTH, "provided x is out of bounds")
	ensure(y < NOISE_HEIGHT, "provided y is out of bounds")
	ensure(z < NOISE_DEPTH, "provided z is out of bounds")

	fract_x := linalg.fract(x)
	fract_y := linalg.fract(y)
	fract_z := linalg.fract(z)

	x2 := x - 1
	if x2 < 0 do x2 = linalg.round(NOISE_WIDTH / zoom) - 1
	xi := int(x)
	x2i := int(x2)

	y2 := y - 1
	if y2 < 0 do y2 = linalg.round(NOISE_HEIGHT / zoom) - 1
	yi := int(y)
	y2i := int(y2)

	z2 := z - 1
	if z2 < 0 do z2 = linalg.round(NOISE_DEPTH / zoom) - 1
	zi := int(z)
	z2i := int(z2)

	value: f64 = 0
	value += fract_x * fract_y * fract_z * noise[get_noise_index(xi, yi, zi)]
	value += (1 - fract_x) * fract_y * fract_z * noise[get_noise_index(x2i, yi, zi)]
	value += fract_x * (1 - fract_y) * fract_z * noise[get_noise_index(xi, y2i, zi)]
	value += (1 - fract_x) * (1 - fract_y) * fract_z * noise[get_noise_index(x2i, y2i, zi)]
	value += fract_x * fract_y * (1 - fract_z) * noise[get_noise_index(xi, yi, z2i)]
	value += (1 - fract_x) * fract_y * (1 - fract_z) * noise[get_noise_index(x2i, yi, z2i)]
	value += fract_x * (1 - fract_y) * (1 - fract_z) * noise[get_noise_index(xi, y2i, z2i)]
	value += (1 - fract_x) * (1 - fract_y) * (1 - fract_z) * noise[get_noise_index(x2i, y2i, z2i)]

	return value
}

fill_data_array_bytes_turbulence :: proc(noise: []f64, data: []u8, zoom: f64 = 1) {
	ensure(len(noise) == NOISE_LENGTH, "provided noise has incorrect size")
	ensure(len(data) == NOISE_LENGTH * 4, "provided data array has incorrect size")

	for x in 0 ..< NOISE_WIDTH {
		for y in 0 ..< NOISE_HEIGHT {
			for z in 0 ..< NOISE_DEPTH {
				xd := f64(x)
				yd := f64(y)
				zd := f64(z)

				noise_value := u8(get_turbulence(noise, xd, yd, zd, zoom))

				data_start_index := get_noise_index(x, y, z) * 4
				for data_index in data_start_index ..< data_start_index + 3 {
					data[data_index] = noise_value
				}
				data[data_start_index + 3] = 255
			}
		}
	}
}

get_turbulence :: proc(noise: []f64, x, y, z, max_zoom: f64) -> f64 {
	ensure(max_zoom >= 1 && max_zoom <= 64, "provided max_zoom is outside of valid range")
	zoom := max_zoom

	result: f64 = 0

	for zoom >= 1 {
		x_zoom := f64(x) / zoom
		y_zoom := f64(y) / zoom
		z_zoom := f64(z) / zoom

		result += get_smooth_noise(noise, zoom, x_zoom, y_zoom, z_zoom) * zoom
		zoom /= 2
	}

	result = 128 * result / max_zoom

	return result
}

get_noise_index :: proc(i, j, k: int) -> int {
	ensure(i < NOISE_WIDTH, "noise index out of bounds")
	ensure(j < NOISE_HEIGHT, "noise index out of bounds")
	ensure(k < NOISE_DEPTH, "noise index out of bounds")

	return i * NOISE_WIDTH * NOISE_HEIGHT + j * NOISE_WIDTH + k
}
