package shaders

import "core:fmt"
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
	UboRed,
	UboGreen,
	UboBlue,
	UboYellow,
	House,
	Explode,
	Normal,
	Greyscale,
	Planet,
	Asteroid,
	InstancedRect,
	TransformUniformColor,
	BlinnPhongDiffuseSampled,
	BlinnPhongDiffuseSampledMultilights,
	EmptyDepth,
	DepthR,
	BlinnPhongDirectionalShadow,
	BlinnPhongDirectionalShadow2,
	BlinnPhongDirectionalShadow3,
	BlinnPhongDirectionalShadow4,
	BlinnPhongPointLightNormalMap,
	DepthCube,
	BlinnDisplacement,
	BlinnDisplacementSteep,
	BlinnParallaxOcclusionMapping,
	HDR,
	BloomLighting,
	BlurSeparated,
	GBuffer,
	GBufferDebug,
	DeferredShading,
	DeferredShadingVolumes,
	SSAOGeometry,
	SSAOLighting,
	SSAODepth,
	SSAOBlur,
	SingleColorTex,
	PBR,
	PBRTexture,
	EquirectangularTexture,
	SkyboxHDR,
	CubemapConvolution,
	PBRIrradiance,
	CubemapPrefilter,
	BRDFIntegration,
	PBRFull,
	PBRFullTextured,
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
			) or_else panic("Failed to load the position as color shader")

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
				#load("../../shaders/vert/pos_transform.vert"),
				#load("../../shaders/frag/depth.frag"),
			) or_else panic("Failed to load the shader")

	case .SingleColor:
		shaders[.SingleColor] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_transform.vert"),
				#load("../../shaders/frag/single_color.frag"),
			) or_else panic("Failed to load the shader")

	case .UboRed:
		shaders[.UboRed] =
			gl.load_shaders_source(
				#load("../../shaders/vert/ubo_transform.vert"),
				#load("../../shaders/frag/red.frag"),
			) or_else panic("Failed to load the ubo red shader")

	case .UboGreen:
		shaders[.UboGreen] =
			gl.load_shaders_source(
				#load("../../shaders/vert/ubo_transform.vert"),
				#load("../../shaders/frag/green.frag"),
			) or_else panic("Failed to load the ubo green shader")

	case .UboBlue:
		shaders[.UboBlue] =
			gl.load_shaders_source(
				#load("../../shaders/vert/ubo_transform.vert"),
				#load("../../shaders/frag/blue.frag"),
			) or_else panic("Failed to load the ubo blue shader")

	case .UboYellow:
		shaders[.UboYellow] =
			gl.load_shaders_source(
				#load("../../shaders/vert/ubo_transform.vert"),
				#load("../../shaders/frag/yellow.frag"),
			) or_else panic("Failed to load the ubo yello shader")

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
		shaders[.House] = load_triple_shader(
			"house",
			#load("../../shaders/vert/house_color.vert"),
			#load("../../shaders/geom/house.geom"),
			#load("../../shaders/frag/vert_color.frag"),
		)

	case .Explode:
		shaders[.Explode] = load_triple_shader(
			"explode",
			#load("../../shaders/vert/explode.vert"),
			#load("../../shaders/geom/explode.geom"),
			#load("../../shaders/frag/single_tex.frag"),
		)

	case .Normal:
		shaders[.Normal] = load_triple_shader(
			"normal",
			#load("../../shaders/vert/draw_normal.vert"),
			#load("../../shaders/geom/draw_normal.geom"),
			#load("../../shaders/frag/yellow.frag"),
		)

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

	case .TransformUniformColor:
		shaders[.TransformUniformColor] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_transform.vert"),
				#load("../../shaders/frag/uniform_color.frag"),
			) or_else panic("Failed to load the uniform color shader")

	case .BlinnPhongDiffuseSampled:
		shaders[.BlinnPhongDiffuseSampled] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/blinn_phong_material_diffuse_sampled_specular_calculated.frag"),
			) or_else panic("Failed to load the phong_diffuse_sampled shader")

	case .BlinnPhongDiffuseSampledMultilights:
		shaders[.BlinnPhongDiffuseSampledMultilights] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/blinn_phong_material_diffuse_specular_calculated_gamma_corrected_multilight.frag"),
			) or_else panic("Failed to load the phong_diffuse_sampled_multilights shader")

	case .EmptyDepth:
		shaders[.EmptyDepth] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_transform.vert"),
				#load("../../shaders/frag/depth_empty.frag"),
			) or_else panic("Failed to load the empty depth shader")

	case .DepthR:
		shaders[.DepthR] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/depth_r.frag"),
			) or_else panic("Failed to load the texture-to-depth shader")

	case .BlinnPhongDirectionalShadow:
		shaders[.BlinnPhongDirectionalShadow] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform_light.vert"),
				#load("../../shaders/frag/blinn_phong_shadow.frag"),
			) or_else panic("Failed to load the directional shadow shader")

	case .BlinnPhongDirectionalShadow2:
		shaders[.BlinnPhongDirectionalShadow2] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform_light.vert"),
				#load("../../shaders/frag/blinn_phong_shadow_2.frag"),
			) or_else panic("Failed to load the directional shadow shader")

	case .BlinnPhongDirectionalShadow3:
		shaders[.BlinnPhongDirectionalShadow3] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform_vs_out.vert"),
				#load("../../shaders/frag/blinn_phong_shadow_3.frag"),
			) or_else panic("Failed to load the point light shadow shader")

	case .BlinnPhongDirectionalShadow4:
		shaders[.BlinnPhongDirectionalShadow4] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform_vs_out.vert"),
				#load("../../shaders/frag/blinn_phong_shadow_4.frag"),
			) or_else panic("Failed to load the soft point light shadow shader")

	case .DepthCube:
		shaders[.DepthCube] = load_triple_shader(
			"depth cube",
			#load("../../shaders/vert/pos_model.vert"),
			#load("../../shaders/geom/depth_cube.geom"),
			#load("../../shaders/frag/depth_linear.frag"),
		)

	case .BlinnPhongPointLightNormalMap:
		shaders[.BlinnPhongPointLightNormalMap] =
			gl.load_shaders_source(
				#load("../../shaders/vert/normal_mapped.vert"),
				#load("../../shaders/frag/normal_map_blinn_phong_point_light.frag"),
			) or_else panic("Failed to load the normal mapping shader")

	case .BlinnDisplacement:
		shaders[.BlinnDisplacement] =
			gl.load_shaders_source(
				#load("../../shaders/vert/normal_mapped.vert"),
				#load("../../shaders/frag/blinn_displacement.frag"),
			) or_else panic("Failed to load the blinn displacement shader")

	case .BlinnDisplacementSteep:
		shaders[.BlinnDisplacementSteep] =
			gl.load_shaders_source(
				#load("../../shaders/vert/normal_mapped.vert"),
				#load("../../shaders/frag/blinn_displacement_steep.frag"),
			) or_else panic("Failed to load the steep blinn displacement shader")

	case .BlinnParallaxOcclusionMapping:
		shaders[.BlinnParallaxOcclusionMapping] =
			gl.load_shaders_source(
				#load("../../shaders/vert/normal_mapped.vert"),
				#load("../../shaders/frag/blinn_parallax_occlusion_mapping.frag"),
			) or_else panic("Failed to load the parallax occlusion mapping shader")

	case .HDR:
		shaders[.HDR] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/hdr.frag"),
			) or_else panic("Failed to load the HDR shader")

	case .BloomLighting:
		shaders[.BloomLighting] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/bloom_lighting.frag"),
			) or_else panic("Failed to load the bloom lighting shader")

	case .BlurSeparated:
		shaders[.BlurSeparated] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/blur_separated.frag"),
			) or_else panic("Failed to load the blur shader")

	case .GBuffer:
		shaders[.GBuffer] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_normal_transform.vert"),
				#load("../../shaders/frag/g_buffer.frag"),
			) or_else panic("Failed to load the g-buffer shader")

	case .GBufferDebug:
		shaders[.GBufferDebug] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/g_buffer_debug.frag"),
			) or_else panic("Failed to load the g-buffer shader")

	case .DeferredShading:
		shaders[.DeferredShading] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/deferred_shading.frag"),
			) or_else panic("Failed to load the deferred shading shader")

	case .DeferredShadingVolumes:
		shaders[.DeferredShadingVolumes] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/deferred_shading_volumes.frag"),
			) or_else panic("Failed to load the deferred shading shader")

	case .SSAOGeometry:
		shaders[.SSAOGeometry] =
			gl.load_shaders_source(
				#load("../../shaders/vert/ssao_geometry.vert"),
				#load("../../shaders/frag/ssao_geometry.frag"),
			) or_else panic("Failed to load the SSAO Geometry shader")

	case .SSAODepth:
		shaders[.SSAODepth] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/ssao_depth.frag"),
			) or_else panic("Failed to load the SSAO Depth shader")

	case .SSAOBlur:
		shaders[.SSAOBlur] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/ssao_blur.frag"),
			) or_else panic("Failed to load the SSAO Blur shader")

	case .SSAOLighting:
		shaders[.SSAOLighting] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/ssao_lighting.frag"),
			) or_else panic("Failed to load the SSAO Lighting shader")

	case .SingleColorTex:
		shaders[.SingleColorTex] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/single_color_tex.frag"),
			) or_else panic("Failed to load the single color texture shader")

	case .PBR:
		shaders[.PBR] =
			gl.load_shaders_source(#load("../../shaders/vert/pbr.vert"), #load("../../shaders/frag/pbr.frag")) or_else panic(
				"Failed to load the PBR shader",
			)

	case .PBRTexture:
		shaders[.PBRTexture] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pbr.vert"),
				#load("../../shaders/frag/pbr_texture.frag"),
			) or_else panic("Failed to load the PBR texture shader")

	case .EquirectangularTexture:
		shaders[.EquirectangularTexture] =
			gl.load_shaders_source(
				#load("../../shaders/vert/world_position.vert"),
				#load("../../shaders/frag/equirectangluar_to_cubemap.frag"),
			) or_else panic("Failed to load the equirectangluar texture shader")

	case .SkyboxHDR:
		shaders[.SkyboxHDR] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex_pv.vert"),
				#load("../../shaders/frag/skybox_hdr.frag"),
			) or_else panic("Failed to load the SkyboxHDR shader")

	case .CubemapConvolution:
		shaders[.CubemapConvolution] =
			gl.load_shaders_source(
				#load("../../shaders/vert/world_position.vert"),
				#load("../../shaders/frag/convolute_skybox.frag"),
			) or_else panic("Failed to load the SkyboxHDR shader")

	case .PBRIrradiance:
		shaders[.PBRIrradiance] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pbr.vert"),
				#load("../../shaders/frag/pbr_irradiance.frag"),
			) or_else panic("Failed to load the PBR Irradiance shader")

	case .CubemapPrefilter:
		shaders[.CubemapPrefilter] =
			gl.load_shaders_source(
				#load("../../shaders/vert/world_position.vert"),
				#load("../../shaders/frag/prefilter_skybox.frag"),
			) or_else panic("Failed to load the Cubemap Prefilter shader")

	case .BRDFIntegration:
		shaders[.BRDFIntegration] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pos_tex.vert"),
				#load("../../shaders/frag/brdf_integration.frag"),
			) or_else panic("Failed to load the BRDF Integration shader")

	case .PBRFull:
		shaders[.PBRFull] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pbr.vert"),
				#load("../../shaders/frag/pbr_full.frag"),
			) or_else panic("Failed to load the PBR Full shader")

	case .PBRFullTextured:
		shaders[.PBRFullTextured] =
			gl.load_shaders_source(
				#load("../../shaders/vert/pbr.vert"),
				#load("../../shaders/frag/pbr_full_textured.frag"),
			) or_else panic("Failed to load the PBR Full Textured shader")

	}
}

delete_shaders :: proc() {
	for key, shader in shaders {
		if shader != 0 do gl.DeleteProgram(shader)
	}
}

load_triple_shader :: proc(name, frag, geom, vert: string) -> u32 {
	individual_shaders: [3]u32 = {
		gl.compile_shader_from_source(frag, gl.Shader_Type.VERTEX_SHADER) or_else fmt.panicf(
			"Failed to load the {} vertex shader",
			name,
		),
		gl.compile_shader_from_source(geom, gl.Shader_Type.GEOMETRY_SHADER) or_else fmt.panicf(
			"Failed to load the {} geometry shader",
			name,
		),
		gl.compile_shader_from_source(vert, gl.Shader_Type.FRAGMENT_SHADER) or_else fmt.panicf(
			"Failed to load the {} fragment shader",
			name,
		),
	}

	defer for shader in individual_shaders {
		gl.DeleteShader(shader)
	}

	shader :=
		gl.create_and_link_program(individual_shaders[:]) or_else fmt.panicf("Failed to compile and link {} shader", name)

	return shader
}
