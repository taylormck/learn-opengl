package primitives

import "../render"
import "../types"
import "../utils"
import "core:log"
import "core:math"
import gl "vendor:OpenGL"

@(private = "file")
NUM_SEGMENTS :: 64

@(private = "file")
NUM_VERTICES :: (NUM_SEGMENTS + 1) * (NUM_SEGMENTS + 1)

@(private = "file")
NUM_INDICES :: NUM_SEGMENTS * NUM_SEGMENTS * 6

@(private = "file")
sphere_vertices: [dynamic]render.Vertex

@(private = "file")
sphere_indices: [dynamic]u32

@(private = "file")
vao, vbo, ebo: u32

sphere_init :: proc(location := #caller_location) {
	log.info("Initializing sphere", location = location)
	sphere_vertices = make([dynamic]render.Vertex, NUM_VERTICES)
	sphere_indices = make([dynamic]u32, NUM_INDICES)

	// Create the vertices
	for i in 0 ..= NUM_SEGMENTS {
		for j in 0 ..= NUM_SEGMENTS {
			// Create the vertex
			y := math.cos(math.to_radians_f32(180.0 - f32(i) * 180.0 / NUM_SEGMENTS))
			x := -math.cos(math.to_radians_f32(f32(j) * 360.0 / NUM_SEGMENTS)) * abs(math.cos(math.asin(y)))
			z := math.sin(math.to_radians_f32(f32(j) * 360.0 / NUM_SEGMENTS)) * abs(math.cos(math.asin(y)))

			index := i * (NUM_SEGMENTS + 1) + j

			vertex := &sphere_vertices[index]

			vertex.position = types.Vec3{x, y, z}
			vertex.texture_coords = types.Vec2{f32(j) / NUM_SEGMENTS, f32(i) / NUM_SEGMENTS}

			// Because we're making a unit sphere, there's no need to normalize the normal.
			vertex.normal = vertex.position

			// Use the normal color for debugging
			vertex.color = vertex.normal * 0.5 + 0.5

			// TODO: calculate the bitangent and tangent
		}
	}

	// Set the indices
	for i in 0 ..< NUM_SEGMENTS {
		for j in 0 ..< NUM_SEGMENTS {
			i := u32(i)
			j := u32(j)
			index := 6 * (i * NUM_SEGMENTS + j)
			sphere_indices[index] = i * (NUM_SEGMENTS + 1) + j
			sphere_indices[index + 1] = i * (NUM_SEGMENTS + 1) + j + 1
			sphere_indices[index + 2] = (i + 1) * (NUM_SEGMENTS + 1) + j
			sphere_indices[index + 3] = i * (NUM_SEGMENTS + 1) + j + 1
			sphere_indices[index + 4] = (i + 1) * (NUM_SEGMENTS + 1) + j + 1
			sphere_indices[index + 5] = (i + 1) * (NUM_SEGMENTS + 1) + j
		}
	}
}

sphere_destroy :: proc(location := #caller_location) {
	log.info("Destorying the sphere data", location = location)
	delete(sphere_vertices)
	delete(sphere_indices)
}

sphere_send_to_gpu :: proc(location := #caller_location) {
	ensure(vao == 0, "attempted to send sphere to GPU twice.")
	ensure(vbo == 0, "attempted to send sphere to GPU twice.")
	ensure(ebo == 0, "attempted to send sphere to GPU twice.")
	ensure(len(sphere_vertices) > 0, "attempted to send sphere to GPU before initializing")
	log.info("Sending sphere data to the GPU", location = location)

	gl.GenVertexArrays(1, &vao)

	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	render.send_vertices_to_gpu(sphere_vertices[:])

	gl.GenBuffers(1, &ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(sphere_indices), raw_data(sphere_indices), gl.STATIC_DRAW)
}

sphere_clear_from_gpu :: proc(location := #caller_location) {
	ensure(vao != 0, "attempted to remove sphere from GPU but was already removed.")
	ensure(vbo != 0, "attempted to remove sphere from GPU but was already removed.")
	ensure(ebo != 0, "attempted to remove sphere from GPU but was already removed.")
	log.info("Clearing sphere data from the GPU", location = location)

	gl.DeleteBuffers(1, &vbo)
	vbo = 0

	gl.DeleteBuffers(1, &ebo)
	ebo = 0

	gl.DeleteVertexArrays(1, &vao)
	vao = 0
}

sphere_draw :: proc() {
	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)

	gl.DrawElements(gl.TRIANGLES, i32(len(sphere_indices)), gl.UNSIGNED_INT, nil)
}
