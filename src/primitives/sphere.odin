package primitives

import "../render"
import "../types"
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
sphere_vao, sphere_vbo, sphere_ebo: u32

sphere_send_to_gpu :: proc() {
	assert(sphere_vao == 0, "attempted to send sphere to GPU twice.")
	assert(sphere_vbo == 0, "attempted to send sphere to GPU twice.")
	assert(len(sphere_vertices) > 0, "attempted to send sphere to GPU before initializing")

	gl.GenVertexArrays(1, &sphere_vao)

	gl.BindVertexArray(sphere_vao)
	defer gl.BindVertexArray(0)

	gl.GenBuffers(1, &sphere_vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, sphere_vbo)
	defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(render.Vertex) * len(sphere_vertices),
		raw_data(sphere_vertices),
		gl.STATIC_DRAW,
	)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, position))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, texture_coords))
	gl.EnableVertexAttribArray(1)

	gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, normal))
	gl.EnableVertexAttribArray(2)

	gl.VertexAttribPointer(3, 3, gl.FLOAT, gl.FALSE, size_of(render.Vertex), offset_of(render.Vertex, color))
	gl.EnableVertexAttribArray(3)

	gl.GenBuffers(1, &sphere_ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, sphere_ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(sphere_indices), raw_data(sphere_indices), gl.STATIC_DRAW)
}

sphere_clear_from_gpu :: proc() {
	gl.DeleteBuffers(1, &sphere_vbo)
	gl.DeleteBuffers(1, &sphere_ebo)
	gl.DeleteVertexArrays(1, &sphere_vao)
}

sphere_draw :: proc() {
	gl.BindVertexArray(sphere_vao)
	defer gl.BindVertexArray(0)

	gl.DrawElements(gl.TRIANGLES, i32(len(sphere_indices)), gl.UNSIGNED_INT, nil)
}

sphere_init :: proc() {
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

			// Use the texture coordinates for debugging
			// vertex.color = types.Vec3{vertex.texture_coords.x, vertex.texture_coords.y, 0}

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

sphere_destroy :: proc() {
	delete(sphere_vertices)
	delete(sphere_indices)
}
