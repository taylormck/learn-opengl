package tableau

import gl "vendor:OpenGL"

// full_screen_shader, depth_shader, single_color_shader, house_shader, explode_shader, normal_shader: u32
// greyscale_shader, invert_shader: u32
// planet_shader, asteroid_shader: u32
Shader :: enum {
	Mesh,
	Texture,
	Light,
	Skybox,
	SkyboxReflect,
	SkyboxRefract,
	Fullscreen,
	Depth,
	SingleColor,
	House,
	Explode,
	Normal,
	Greyscale,
	Invert,
	Planet,
	Asteroid,
	InstancedRect,
}

ShaderMap :: map[Shader]u32
shaders: ShaderMap

init_shaders :: proc(wanted_shaders: ..Shader) {
	for shader in wanted_shaders {
		if shaders[shader] != 0 do continue

		init_shader(shader)
	}
}

init_shader :: proc(shader: Shader) {
	switch shader {
	case .Mesh:
		shaders[.Mesh] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_sampled_multilights.frag"),
			) or_else panic("Failed to load the shader")

	case .Texture:
		shaders[.Texture] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_transform.vert"),
				#load("../../shaders/frag/single_tex.frag"),
			) or_else panic("Failed to load the shader")

	case .Depth:
		shaders[.Depth] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/depth.frag"),
			) or_else panic("Failed to load the shader")

	case .SingleColor:
		shaders[.SingleColor] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_transform.vert"),
				#load("../../shaders/frag/single_color.frag"),
			) or_else panic("Failed to load the shader")

	case .Light:
		shaders[.Light] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_transform.vert"),
				#load("../../shaders/frag/light_color.frag"),
			) or_else panic("Failed to load the light shader")

	case .Fullscreen:
		shaders[.Fullscreen] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/edge_kernel.frag"),
			) or_else panic("Failed to load the full screen shader")

	case .Greyscale:
		shaders[.Greyscale] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/flat_tex_greyscale.frag"),
			) or_else panic("Failed to load the full screen shader")

	case .Invert:
		shaders[.Invert] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/flat_tex_invert.frag"),
			) or_else panic("Failed to load the full screen shader")

	case .Skybox:
		shaders[.Skybox] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_pv.vert"),
				#load("../../shaders/frag/skybox.frag"),
			) or_else panic("Failed to load the skybox shader")

	case .SkyboxReflect:
		shaders[.SkyboxReflect] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_normal_transform.vert"),
				#load("../../shaders/frag/skybox_reflection.frag"),
			) or_else panic("Failed to load the skybox reflection shader")

	case .SkyboxRefract:
		shaders[.SkyboxRefract] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_normal_transform.vert"),
				#load("../../shaders/frag/skybox_refraction.frag"),
			) or_else panic("Failed to load the skybox refraction shader")

	case .House:
		house_shaders: [3]u32 = {
			gl.compile_shader_from_source(
				#load("../../shaders/vert/pos_and_color.vert"),
				gl.Shader_Type.VERTEX_SHADER,
			) or_else panic("Failed to load the house vertex shader"),
			gl.compile_shader_from_source(
				#load("../../shaders/geom/house.geom"),
				gl.Shader_Type.GEOMETRY_SHADER,
			) or_else panic("Failed to load the house geometry shader"),
			gl.compile_shader_from_source(
				#load("../../shaders/frag/vert_color.frag"),
				gl.Shader_Type.FRAGMENT_SHADER,
			) or_else panic("Failed to load the house fragment shader"),
		}

		shaders[.House] = gl.create_and_link_program(house_shaders[:]) or_else panic("Failed to link house shader")

		for shader in house_shaders {
			gl.DeleteShader(shader)
		}

	case .Explode:
		explode_shaders: [3]u32 = {
			gl.compile_shader_from_source(
				#load("../../shaders/vert/explode.vert"),
				gl.Shader_Type.VERTEX_SHADER,
			) or_else panic("Failed to load the explode vertex shader"),
			gl.compile_shader_from_source(
				#load("../../shaders/geom/explode.geom"),
				gl.Shader_Type.GEOMETRY_SHADER,
			) or_else panic("Failed to load the explode geometry shader"),
			gl.compile_shader_from_source(
				#load("../../shaders/frag/single_tex.frag"),
				gl.Shader_Type.FRAGMENT_SHADER,
			) or_else panic("Failed to load the explode fragment shader"),
		}

		shaders[.Explode] = gl.create_and_link_program(explode_shaders[:]) or_else panic("Failed to link explode shader")

		for shader in explode_shaders {
			gl.DeleteShader(shader)
		}

	case .Normal:
		normal_shaders: [3]u32 = {
			gl.compile_shader_from_source(
				#load("../../shaders/vert/draw_normal.vert"),
				gl.Shader_Type.VERTEX_SHADER,
			) or_else panic("Failed to load the explode vertex shader"),
			gl.compile_shader_from_source(
				#load("../../shaders/geom/draw_normal.geom"),
				gl.Shader_Type.GEOMETRY_SHADER,
			) or_else panic("Failed to load the explode geometry shader"),
			gl.compile_shader_from_source(
				#load("../../shaders/frag/yellow.frag"),
				gl.Shader_Type.FRAGMENT_SHADER,
			) or_else panic("Failed to load the explode fragment shader"),
		}

		shaders[.Normal] =
			gl.create_and_link_program(normal_shaders[:]) or_else panic("Failed to compile and link normal shader")

		for shader in normal_shaders {
			gl.DeleteShader(shader)
		}

	case .Planet:
		shaders[.Planet] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_sampled_directional_light.frag"),
			) or_else panic("Failed to load the planet shader")

	case .Asteroid:
		shaders[.Asteroid] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform_instanced.vert"),
				#load("../../shaders/frag/phong_material_sampled_directional_light.frag"),
			) or_else panic("Failed to load the asteroid shader")


	case .InstancedRect:
		shaders[.InstancedRect] =
			gl.load_shaders_source(
				#load("../../shaders/vert/instanced_color.vert"),
				#load("../../shaders/frag/vert_color.frag"),
			) or_else panic("Failed to load the instanced rect shader")
	}
}

delete_shaders :: proc() {
	for key, shader in shaders {
		if shader != 0 do gl.DeleteProgram(shader)
	}
}
