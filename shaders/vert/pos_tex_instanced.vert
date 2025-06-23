#version 330 core
#extension GL_ARB_shader_viewport_layer_array : require

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec2 aTexCoord;

out VS_OUT {
	vec3 frag_position;
	vec3 tex_coords;
}
vs_out;

uniform int depth;

void main() {
	gl_Layer = gl_InstanceID;
	float z = float(gl_InstanceID) / float(depth);

	vs_out.tex_coords = vec3(aTexCoord, z);
	vs_out.frag_position = vec3(aPos.xy, z);

	gl_Position = vec4(vs_out.frag_position, 1.0);
}
