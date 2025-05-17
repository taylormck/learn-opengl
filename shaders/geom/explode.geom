#version 330 core
layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in VS_OUT {
	vec3 frag_position;
	vec3 normal;
	vec2 tex_coords;
}
gs_in[];

out vec2 tex_coords;

uniform float time;

const float magnitude = 2.0;

vec4 explode(vec4 position, vec3 normal) {
	vec3 direction = normal * ((sin(time) + 1.0) / 2.0) * magnitude;
	return position + vec4(direction, 0.0);
}

vec3 get_normal() {
	vec3 a = vec3(gl_in[0].gl_Position) - vec3(gl_in[1].gl_Position);
	vec3 b = vec3(gl_in[2].gl_Position) - vec3(gl_in[1].gl_Position);
	return normalize(cross(a, b));
}

void main() {
	vec3 normal = get_normal();

	for (int i = 0; i < 3; i += 1) {
		gl_Position = explode(gl_in[i].gl_Position, normal);
		tex_coords = gs_in[i].tex_coords;
		EmitVertex();
	}

	EndPrimitive();
}
