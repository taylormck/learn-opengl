#version 330 core
layout(triangles) in;
layout(line_strip, max_vertices = 6) out;

in VS_OUT {
	vec3 normal;
}
gs_in[];

const float magnitude = 0.2;

uniform mat4 projection;

void generate_line(int index) {
	gl_Position = projection * gl_in[index].gl_Position;
	EmitVertex();

	vec3 normal = gs_in[index].normal * magnitude;
	gl_Position = projection * (gl_in[index].gl_Position + vec4(normal, 0.0));
	EmitVertex();

	EndPrimitive();
}

void main() {
	generate_line(0);
	generate_line(1);
	generate_line(2);
}
