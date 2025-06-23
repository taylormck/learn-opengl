#version 330 core
layout(triangles) in;

// 3 * 256 = 768
layout(triangle_strip, max_vertices = 768) out;

out vec4 frag_pos;

uniform int depth;

void main() {
	for (int z = 0; z < depth; z += 1) {
		gl_Layer = z;

		for (int i = 0; i < 3; i += 1) {
			frag_pos = gl_in[i].gl_Position;
			frag_pos.z = float(z);
			gl_Position = frag_pos;

			EmitVertex();
		}

		EndPrimitive();
	}
}
