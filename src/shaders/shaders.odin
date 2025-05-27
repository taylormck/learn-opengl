package shaders

import gl "vendor:OpenGL"

Shader :: enum {
	Orange,
	Yellow,
	UniformColor,
	VertexColor,
	UpsideDown,
	Offset,
	PositionAsColor,
	Texture,
	ColorTexture,
	DoubleTexture,
	Exercise_04_03,
	Exercise_04_04,
	Exercise_04_06,
	TransformTexture,
	TransformDoubleTexture,
	ObjLightColor,
	Diffuse,
	Phong,
	PhongDiffuseSampled,
	PhongSampled,
	PhongSampledInvertedSpecular,
	PhongEmissive,
	PhongDirectional,
	PhongPointLight,
	PhongSpotLight,
	PhongMultiLight,
	Mesh,
	Light,
	Skybox,
	SkyboxReflect,
	SkyboxRefract,
	Edge,
	Depth,
	Invert,
	Sharpen,
	Blur,
	SingleColor,
	House,
	Explode,
	Normal,
	Greyscale,
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
	case .Orange:
		shaders[.Orange] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos.vert"),
				#load("../../shaders/frag/orange.frag"),
			) or_else panic("Failed to load the orange shader")

	case .Yellow:
		shaders[.Yellow] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos.vert"),
				#load("../../shaders/frag/yellow.frag"),
			) or_else panic("Failed to load the yellow shader")

	case .UniformColor:
		shaders[.UniformColor] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos.vert"),
				#load("../../shaders/frag/uniform_color.frag"),
			) or_else panic("Failed to load the uniform color shader")

	case .VertexColor:
		shaders[.VertexColor] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_color.vert"),
				#load("../../shaders/frag/vert_color.frag"),
			) or_else panic("Failed to load the shader")

	case .UpsideDown:
		shaders[.UpsideDown] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_upside_down.vert"),
				#load("../../shaders/frag/orange.frag"),
			) or_else panic("Failed to load the upside down shader")

	case .Offset:
		shaders[.Offset] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_uniform_offset.vert"),
				#load("../../shaders/frag/orange.frag"),
			) or_else panic("Failed to load the upside down shader")

	case .PositionAsColor:
		shaders[.PositionAsColor] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_as_color.vert"),
				#load("../../shaders/frag/vert_color.frag"),
			) or_else panic("Failed to load the upside down shader")

	case .Texture:
		shaders[.Texture] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/single_tex.frag"),
			) or_else panic("Failed to load the texture shader")

	case .ColorTexture:
		shaders[.ColorTexture] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_color_tex.vert"),
				#load("../../shaders/frag/tex_color.frag"),
			) or_else panic("Failed to load the color texture shader")

	case .DoubleTexture:
		shaders[.DoubleTexture] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/double_tex.frag"),
			) or_else panic("Failed to load the double texture shader")

	case .Exercise_04_03:
		shaders[.Exercise_04_03] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/exercise_04_03.frag"),
			) or_else panic("Failed to load the exercise_04_03 shader")

	case .Exercise_04_04:
		shaders[.Exercise_04_04] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/exercise_04_04.frag"),
			) or_else panic("Failed to load the exercise_04_04 shader")

	case .Exercise_04_06:
		shaders[.Exercise_04_06] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/exercise_04_06.frag"),
			) or_else panic("Failed to load the exercise_04_04 shader")

	case .TransformTexture:
		shaders[.TransformTexture] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_transform.vert"),
				#load("../../shaders/frag/single_tex.frag"),
			) or_else panic("Failed to load the transform texture shader")

	case .TransformDoubleTexture:
		shaders[.TransformDoubleTexture] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_transform.vert"),
				#load("../../shaders/frag/double_tex.frag"),
			) or_else panic("Failed to load the transform texture shader")

	case .ObjLightColor:
		shaders[.ObjLightColor] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_transform.vert"),
				#load("../../shaders/frag/obj_light_color.frag"),
			) or_else panic("Failed to load the obj_light_color shader")

	case .Light:
		shaders[.Light] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_transform.vert"),
				#load("../../shaders/frag/light_color.frag"),
			) or_else panic("Failed to load the light shader")

	case .Diffuse:
		shaders[.Diffuse] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_normal_transform.vert"),
				#load("../../shaders/frag/diffuse.frag"),
			) or_else panic("Failed to load the diffuse shader")

	case .Phong:
		shaders[.Phong] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_calculated.frag"),
			) or_else panic("Failed to load the phong shader")

	case .PhongDiffuseSampled:
		shaders[.PhongDiffuseSampled] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_diffuse_sampled_specular_calculated.frag"),
			) or_else panic("Failed to load the phong_diffuse_sampled shader")

	case .PhongSampled:
		shaders[.PhongSampled] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_sampled.frag"),
			) or_else panic("Failed to load the phong_sampled shader")

	case .PhongSampledInvertedSpecular:
		shaders[.PhongSampledInvertedSpecular] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_sampled_inverted_specular.frag"),
			) or_else panic("Failed to load the phong_sampled_inverted_specular shader")

	case .PhongEmissive:
		shaders[.PhongEmissive] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_sampled_emissive.frag"),
			) or_else panic("Failed to load the phong_sampled_inverted_specular shader")

	case .PhongDirectional:
		shaders[.PhongDirectional] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_sampled_directional_light.frag"),
			) or_else panic("Failed to load the phong_directional shader")

	case .PhongPointLight:
		shaders[.PhongPointLight] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_sampled_point_light.frag"),
			) or_else panic("Failed to load the phong_point_light shader")

	case .PhongSpotLight:
		shaders[.PhongSpotLight] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_sampled_spot_light.frag"),
			) or_else panic("Failed to load the phong_spot_light shader")

	case .PhongMultiLight:
		shaders[.PhongMultiLight] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_sampled_multilights.frag"),
			) or_else panic("Failed to load the phong_multi_light shader")

	case .Mesh:
		shaders[.Mesh] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/phong_material_sampled_multilights.frag"),
			) or_else panic("Failed to load the mesh shader")

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

	case .Edge:
		shaders[.Edge] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/edge_kernel.frag"),
			) or_else panic("Failed to load the edge shader")

	case .Greyscale:
		shaders[.Greyscale] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/flat_tex_greyscale.frag"),
			) or_else panic("Failed to load the greyscale shader")

	case .Invert:
		shaders[.Invert] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/flat_tex_invert.frag"),
			) or_else panic("Failed to load the invert shader")

	case .Sharpen:
		shaders[.Sharpen] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/sharpen_kernel.frag"),
			) or_else panic("Failed to load the blur shader")

	case .Blur:
		shaders[.Blur] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/blur_kernel.frag"),
			) or_else panic("Failed to load the blur shader")

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
				#load("../../shaders/vert/house_color.vert"),
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
