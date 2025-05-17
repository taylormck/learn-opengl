#version 330 core
layout(points) in;
layout(triangle_strip, max_vertices = 5) out;

in VS_OUT {
	vec3 vert_color;
}
gs_in[];

out vec3 vert_color;

void build_house(vec4 position) {
	vert_color = gs_in[0].vert_color;
	gl_Position = position + vec4(-0.2, -0.2, 0.0, 0.0); // bottom-left
	EmitVertex();
	gl_Position = position + vec4(0.2, -0.2, 0.0, 0.0); // bottom-right
	EmitVertex();
	gl_Position = position + vec4(-0.2, 0.2, 0.0, 0.0); // top-left
	EmitVertex();
	gl_Position = position + vec4(0.2, 0.2, 0.0, 0.0); // bottom-left
	EmitVertex();

	vert_color = vec3(1.0, 1.0, 1.0);
	gl_Position = position + vec4(0.0, 0.4, 0.0, 0.0); // bottom-left
	EmitVertex();
	EndPrimitive();
}

void main() {
	build_house(gl_in[0].gl_Position);
}
