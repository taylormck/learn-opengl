package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:slice"
import "parse/obj"
import "primitives"
import "render"
import "types"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"

WIDTH :: 800
HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

point_lights := [?]render.PointLight {
	{
		position = {0.4, 0.2, 2},
		ambient = {0.2, 0.2, 0.2},
		diffuse = {0.5, 0.5, 0.5},
		specular = {1, 1, 1},
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {2.3, -3.3, -4},
		ambient = {0.2, 0.2, 0.2},
		diffuse = {1, 0, 0},
		specular = {1, 1, 1},
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {-4, 2, -12},
		ambient = {0.2, 0.2, 0.2},
		diffuse = {0, 1, 0},
		specular = {1, 1, 1},
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
	{
		position = {0, 0, -3},
		ambient = {0.2, 0.2, 0.2},
		diffuse = {0, 0, 1},
		specular = {1, 1, 1},
		constant = 1,
		linear = 0.09,
		quadratic = 0.032,
	},
}

directional_light := render.DirectionalLight {
	direction = {-0.2, -1, -0.3},
	ambient   = {0.2, 0.2, 0.2},
	diffuse   = {0.5, 0.5, 0.5},
	specular  = {1, 1, 1},
}

spot_light := render.SpotLight {
	ambient      = {0.2, 0.2, 0.2},
	diffuse      = {0.5, 0.5, 0.5},
	specular     = {1, 1, 1},
	inner_cutoff = math.cos(linalg.to_radians(f32(12.5))),
	outer_cutoff = math.cos(linalg.to_radians(f32(17.5))),
}

camera := render.Camera {
	type         = .Flying,
	position     = {0, 0, 3},
	direction    = {0, 0, -1},
	up           = {0, 1, 0},
	fov          = linalg.to_radians(f32(45)),
	aspect_ratio = f32(WIDTH) / HEIGHT,
	near         = 0.1,
	far          = 1000,
	speed        = 5,
}

marble_texture, metal_texture, grass_texture, window_texture: render.Texture

fbo, fb_texture, rbo: u32
cubemap: primitives.Cubemap

skybox_shader, mesh_shader, texture_shader, light_shader, skybox_reflect_shader, skybox_refract_shader: u32
full_screen_shader, depth_shader, single_color_shader, house_shader, explode_shader, normal_shader: u32
planet_shader: u32
NUM_ASTEROIDS :: 1000

asteroid_model_transforms: [dynamic]types.TransformMatrix

instanced_rect_shader, instanced_rect_offset_vbo: u32

instanced_rect_translations: [100]types.Vec2

main :: proc() {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	if !bool(glfw.Init()) {
		panic("GLFW failed to init.")
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)

	window := glfw.CreateWindow(WIDTH, HEIGHT, "Renderer", nil, nil)
	defer glfw.DestroyWindow(window)

	if window == nil {
		panic("GLFW failed to open the window.")
	}

	glfw.MakeContextCurrent(window)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	gl.Viewport(0, 0, WIDTH, HEIGHT)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)
	glfw.SetCursorPosCallback(window, mouse_callback)
	glfw.SetScrollCallback(window, scroll_callback)

	mesh_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/pos_tex_normal_transform.vert"),
			#load("../shaders/frag/phong_material_sampled_multilights.frag"),
		) or_else panic("Failed to load the shader")
	defer gl.DeleteProgram(mesh_shader)

	texture_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/pos_tex_transform.vert"),
			#load("../shaders/frag/single_tex.frag"),
		) or_else panic("Failed to load the shader")
	defer gl.DeleteProgram(texture_shader)

	depth_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/pos_tex_normal_transform.vert"),
			#load("../shaders/frag/depth.frag"),
		) or_else panic("Failed to load the shader")
	defer gl.DeleteProgram(depth_shader)

	single_color_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/pos_tex_normal_transform.vert"),
			#load("../shaders/frag/single_color.frag"),
		) or_else panic("Failed to load the shader")
	defer gl.DeleteProgram(single_color_shader)

	light_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/pos_transform.vert"),
			#load("../shaders/frag/light_color.frag"),
		) or_else panic("Failed to load the light shader")
	defer gl.DeleteProgram(light_shader)

	full_screen_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/pos_tex.vert"),
			#load("../shaders/frag/edge_kernel.frag"),
		) or_else panic("Failed to load the full screen shader")

	skybox_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/pos_tex_pv.vert"),
			#load("../shaders/frag/skybox.frag"),
		) or_else panic("Failed to load the skybox shader")

	skybox_reflect_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/pos_normal_transform.vert"),
			#load("../shaders/frag/skybox_reflection.frag"),
		) or_else panic("Failed to load the skybox reflection shader")

	skybox_refract_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/pos_normal_transform.vert"),
			#load("../shaders/frag/skybox_refraction.frag"),
		) or_else panic("Failed to load the skybox refraction shader")

	house_shaders: [3]u32 = {
		gl.compile_shader_from_source(
			#load("../shaders/vert/pos_and_color.vert"),
			gl.Shader_Type.VERTEX_SHADER,
		) or_else panic("Failed to load the house vertex shader"),
		gl.compile_shader_from_source(#load("../shaders/geom/house.geom"), gl.Shader_Type.GEOMETRY_SHADER) or_else panic(
			"Failed to load the house geometry shader",
		),
		gl.compile_shader_from_source(
			#load("../shaders/frag/vert_color.frag"),
			gl.Shader_Type.FRAGMENT_SHADER,
		) or_else panic("Failed to load the house fragment shader"),
	}

	house_shader = gl.create_and_link_program(house_shaders[:]) or_else panic("Failed to compile and link house shader")

	for shader in house_shaders {
		gl.DeleteShader(shader)
	}

	explode_shaders: [3]u32 = {
		gl.compile_shader_from_source(#load("../shaders/vert/explode.vert"), gl.Shader_Type.VERTEX_SHADER) or_else panic(
			"Failed to load the explode vertex shader",
		),
		gl.compile_shader_from_source(#load("../shaders/geom/explode.geom"), gl.Shader_Type.GEOMETRY_SHADER) or_else panic(
			"Failed to load the explode geometry shader",
		),
		gl.compile_shader_from_source(
			#load("../shaders/frag/single_tex.frag"),
			gl.Shader_Type.FRAGMENT_SHADER,
		) or_else panic("Failed to load the explode fragment shader"),
	}

	explode_shader =
		gl.create_and_link_program(explode_shaders[:]) or_else panic("Failed to compile and link explode shader")

	for shader in explode_shaders {
		gl.DeleteShader(shader)
	}

	normal_shaders: [3]u32 = {
		gl.compile_shader_from_source(
			#load("../shaders/vert/draw_normal.vert"),
			gl.Shader_Type.VERTEX_SHADER,
		) or_else panic("Failed to load the explode vertex shader"),
		gl.compile_shader_from_source(
			#load("../shaders/geom/draw_normal.geom"),
			gl.Shader_Type.GEOMETRY_SHADER,
		) or_else panic("Failed to load the explode geometry shader"),
		gl.compile_shader_from_source(#load("../shaders/frag/yellow.frag"), gl.Shader_Type.FRAGMENT_SHADER) or_else panic(
			"Failed to load the explode fragment shader",
		),
	}

	normal_shader =
		gl.create_and_link_program(normal_shaders[:]) or_else panic("Failed to compile and link normal shader")

	for shader in normal_shaders {
		gl.DeleteShader(shader)
	}

	instanced_rect_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/instanced_color.vert"),
			#load("../shaders/frag/vert_color.frag"),
		) or_else panic("Failed to load the instanced rect shader")
	defer gl.DeleteProgram(instanced_rect_shader)

	index := 0
	offset: f32 = 0.1

	for y := -10; y < 10; y += 2 {
		for x := -10; x < 10; x += 2 {
			translation := &instanced_rect_translations[index]
			translation.x = f32(x) / 10.0 + offset
			translation.y = f32(y) / 10.0 + offset
			index += 1
		}
	}

	gl.GenBuffers(1, &instanced_rect_offset_vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, instanced_rect_offset_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(instanced_rect_translations), &instanced_rect_translations, gl.STATIC_DRAW)

	planet_shader =
		gl.load_shaders_source(
			#load("../shaders/vert/pos_tex_normal_transform.vert"),
			#load("../shaders/frag/phong_material_sampled_directional_light.frag"),
		) or_else panic("Failed to load the planet shader")

	scene :=
		obj.load_scene_from_file_obj("models/backpack", "backpack.obj") or_else panic("Failed to load backpack model.")
	defer render.scene_destroy(&scene)

	for _, &mesh in scene.meshes do render.mesh_send_to_gpu(&mesh)
	defer for _, &mesh in scene.meshes do render.mesh_gpu_free(&mesh)

	planet_scene :=
		obj.load_scene_from_file_obj("models/planet", "planet.obj") or_else panic("Failed to load planet model.")
	defer render.scene_destroy(&planet_scene)

	for _, &mesh in planet_scene.meshes do render.mesh_send_to_gpu(&mesh)
	defer for _, &mesh in planet_scene.meshes do render.mesh_gpu_free(&mesh)

	rock_scene := obj.load_scene_from_file_obj("models/rock", "rock.obj") or_else panic("Failed to load rock model.")
	defer render.scene_destroy(&rock_scene)

	for _, &mesh in rock_scene.meshes do render.mesh_send_to_gpu(&mesh)
	defer for _, &mesh in rock_scene.meshes do render.mesh_gpu_free(&mesh)

	asteroid_model_transforms = make([dynamic]types.TransformMatrix, NUM_ASTEROIDS)
	defer delete(asteroid_model_transforms)
	set_asteroid_transforms()

	primitives.cube_send_to_gpu()
	defer primitives.cube_clear_from_gpu()

	primitives.quad_send_to_gpu()
	defer primitives.quad_clear_from_gpu()

	primitives.cross_imposter_send_to_gpu()
	defer primitives.cross_imposter_clear_from_gpu()

	primitives.full_screen_send_to_gpu()
	defer primitives.full_screen_clear_from_gpu()

	cubemap = primitives.cubemap_load("textures/skybox")
	defer primitives.cubemap_free(&cubemap)

	primitives.points_send_to_gpu()
	defer primitives.points_clear_from_gpu()

	gl.UseProgram(mesh_shader)

	render.directional_light_set_uniform(&directional_light, mesh_shader)

	for &point_light, i in point_lights {
		render.point_light_array_set_uniform(&point_light, mesh_shader, u32(i))
	}

	gl.UseProgram(planet_shader)
	render.directional_light_set_uniform(&directional_light, planet_shader)

	metal_texture = render.prepare_texture("textures/metal.png", .Diffuse, true)
	marble_texture = render.prepare_texture("textures/marble.jpg", .Diffuse, true)
	grass_texture = render.prepare_texture("textures/grass.png", .Diffuse, true)
	window_texture = render.prepare_texture("textures/blending_transparent_window.png", .Diffuse, true)

	gl.BindTexture(gl.TEXTURE_2D, grass_texture.id)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	gl.BindTexture(gl.TEXTURE_2D, window_texture.id)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	gl.GenFramebuffers(1, &fbo)
	defer gl.DeleteFramebuffers(1, &fbo)
	gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)

	gl.GenTextures(1, &fb_texture)
	gl.BindTexture(gl.TEXTURE_2D, fb_texture)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, WIDTH, HEIGHT, 0, gl.RGB, gl.UNSIGNED_BYTE, nil)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.BindTexture(gl.TEXTURE_2D, 0)

	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fb_texture, 0)

	gl.GenRenderbuffers(1, &rbo)
	gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
	gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, WIDTH, HEIGHT)
	gl.BindRenderbuffer(gl.RENDERBUFFER, 0)

	gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, rbo)

	if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE do panic("Framebuffer incomplete!")
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	prev_time := f32(glfw.GetTime())

	for !glfw.WindowShouldClose(window) {
		new_time := f32(glfw.GetTime())
		delta := new_time - prev_time

		glfw.PollEvents()
		process_input(window, delta)

		// draw_scene(scene)
		// draw_block_scene()
		// draw_full_screen_scene()
		// draw_box_scene_rearview_mirror()
		// draw_skybox_scene(scene)
		// draw_houses()
		// draw_exploded_model(scene, new_time)
		// draw_normals(scene)
		// draw_instanced_rects()
		draw_asteroid_scene(planet_scene, rock_scene)

		glfw.SwapBuffers(window)
		prev_time = new_time
	}
}

framebuffer_size_callback :: proc "cdecl" (window: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()

	gl.Viewport(0, 0, width, height)
	camera.aspect_ratio = f32(width) / f32(height)
}

draw_scene :: proc(scene: render.Scene, draw_outline: bool = false) {
	gl.Enable(gl.STENCIL_TEST)
	gl.StencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)

	gl.ClearColor(0.1, 0.2, 0.3, 1)
	gl.Enable(gl.DEPTH_TEST)

	if draw_outline {
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT)
		gl.StencilMask(0x00)
		gl.StencilFunc(gl.ALWAYS, 1, 0xff)
		gl.StencilMask(0xff)
	} else {
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	}

	projection := render.camera_get_projection(&camera)
	view := render.camera_get_view(&camera)
	pv := projection * view

	gl.UseProgram(light_shader)

	for point_light in point_lights {
		// NOTE: This is just a quick hack to make the lights look brighter.
		light_color := point_light.diffuse * 2

		model := linalg.matrix4_translate(point_light.position)
		model *= linalg.matrix4_scale_f32({0.2, 0.2, 0.2})
		transform := pv * model

		gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader, "transform"), 1, false, raw_data(&transform))
		gl.Uniform3fv(gl.GetUniformLocation(light_shader, "light_color"), 1, raw_data(&light_color))
		primitives.cube_draw()
	}

	gl.UseProgram(mesh_shader)
	gl.Uniform3fv(gl.GetUniformLocation(mesh_shader, "view_position"), 1, raw_data(&camera.position))

	spot_light.position = camera.position
	spot_light.direction = camera.direction
	render.spot_light_set_uniform(&spot_light, mesh_shader)

	model := linalg.identity(types.TransformMatrix)
	mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
	transform := pv * model
	gl.UniformMatrix4fv(gl.GetUniformLocation(mesh_shader, "transform"), 1, false, raw_data(&transform))
	gl.UniformMatrix4fv(gl.GetUniformLocation(mesh_shader, "model"), 1, false, raw_data(&model))
	gl.UniformMatrix3fv(gl.GetUniformLocation(mesh_shader, "mit"), 1, false, raw_data(&mit))

	for _, &mesh in scene.meshes {
		render.mesh_draw(&mesh, mesh_shader)
	}

	if !draw_outline do return

	// Draw the outline
	gl.StencilFunc(gl.NOTEQUAL, 1, 0xff)
	gl.StencilMask(0x00)
	gl.Disable(gl.DEPTH_TEST)

	gl.UseProgram(single_color_shader)
	gl.Uniform3fv(gl.GetUniformLocation(single_color_shader, "view_position"), 1, raw_data(&camera.position))

	model = linalg.matrix4_scale_f32({1.1, 1.1, 1.1})
	mit = types.SubTransformMatrix(linalg.inverse_transpose(model))
	transform = pv * model

	gl.UniformMatrix4fv(gl.GetUniformLocation(single_color_shader, "transform"), 1, false, raw_data(&transform))
	gl.UniformMatrix4fv(gl.GetUniformLocation(single_color_shader, "model"), 1, false, raw_data(&model))
	gl.UniformMatrix3fv(gl.GetUniformLocation(single_color_shader, "mit"), 1, false, raw_data(&mit))

	for _, &mesh in scene.meshes {
		render.mesh_draw(&mesh, single_color_shader)
	}

	gl.StencilFunc(gl.ALWAYS, 1, 0xff)
	gl.StencilMask(0xff)
	gl.Enable(gl.DEPTH_TEST)
}


draw_block_scene :: proc() {
	gl.ClearColor(0.1, 0.2, 0.3, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	gl.Enable(gl.DEPTH_TEST)

	gl.ActiveTexture(gl.TEXTURE0)

	gl.Uniform1i(gl.GetUniformLocation(texture_shader, "diffuse_0"), 0)
	gl.UseProgram(texture_shader)

	projection := render.camera_get_projection(&camera)
	view := render.camera_get_view(&camera)
	pv := projection * view

	{
		// Draw floor
		gl.BindTexture(gl.TEXTURE_2D, marble_texture.id)
		model := linalg.matrix4_translate(types.Vec3{0, -1, 0})
		model = model * linalg.matrix4_rotate(linalg.to_radians(f32(-90)), types.Vec3{1, 0, 0})
		model = linalg.matrix4_scale_f32(types.Vec3{10, 1, 10}) * model
		transform := pv * model

		gl.UniformMatrix4fv(gl.GetUniformLocation(texture_shader, "transform"), 1, false, raw_data(&transform))

		primitives.quad_draw()
	}

	{
		gl.Enable(gl.CULL_FACE)
		defer gl.Disable(gl.CULL_FACE)

		gl.CullFace(gl.FRONT)
		defer gl.CullFace(gl.BACK)

		cube_positions := [?]types.Vec3{{-2, -0.45, -2.5}, {2, -0.45, -2}}
		for position in cube_positions {
			gl.BindTexture(gl.TEXTURE_2D, metal_texture.id)
			model := linalg.matrix4_translate(position)
			transform := pv * model

			gl.UniformMatrix4fv(gl.GetUniformLocation(texture_shader, "transform"), 1, false, raw_data(&transform))

			primitives.cube_draw()
		}
	}

	gl.Enable(gl.BLEND)
	defer gl.Disable(gl.BLEND)

	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	gl.BindTexture(gl.TEXTURE_2D, grass_texture.id)
	grass_positions := [?]types.Vec3 {
		{0, -0.5, 1.05},
		{-1.5, -0.5, 0.2},
		{3.5, -0.5, 0.51},
		{-0.3, -0.5, -4.3},
		{0.5, -0.5, -1.5},
	}
	for position in grass_positions {
		model := linalg.matrix4_translate(position)
		transform := pv * model
		gl.UniformMatrix4fv(gl.GetUniformLocation(texture_shader, "transform"), 1, false, raw_data(&transform))

		primitives.cross_imposter_draw()
	}

	gl.BindTexture(gl.TEXTURE_2D, window_texture.id)
	window_positions := [?]types.Vec3 {
		{1, -0.5, 0.55},
		{-1.75, -0.5, -0.58},
		{1.5, -0.5, 1},
		{-0.3, -0.5, -2.6},
		{0.5, -0.5, -0.7},
	}
	slice.sort_by(window_positions[:], distance_order)
	for position in window_positions {
		model := linalg.matrix4_translate(position)
		transform := pv * model
		gl.UniformMatrix4fv(gl.GetUniformLocation(texture_shader, "transform"), 1, false, raw_data(&transform))

		primitives.quad_draw()
	}
}

draw_full_screen_scene :: proc(full_screen_shader, light_shader, texture_shader, single_color_shader: u32) {
	gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)
	// NOTE: draw_block_scene clears the buffers for us
	draw_block_scene()

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.ClearColor(1, 1, 1, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.Disable(gl.DEPTH_TEST)
	gl.BindTexture(gl.TEXTURE_2D, fb_texture)

	gl.UseProgram(full_screen_shader)
	primitives.full_screen_draw()
}

draw_box_scene_rearview_mirror :: proc(light_shader, texture_shader, single_color_shader: u32) {
	gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)
	// NOTE: draw_block_scene clears the buffers for us

	camera.direction = -camera.direction
	draw_block_scene()
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	camera.direction = -camera.direction
	draw_block_scene()

	gl.UseProgram(texture_shader)
	gl.BindTexture(gl.TEXTURE_2D, fb_texture)

	gl.Enable(gl.STENCIL_TEST)
	gl.Disable(gl.DEPTH_TEST)
	gl.Clear(gl.STENCIL_BUFFER_BIT)
	gl.StencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)
	gl.StencilFunc(gl.ALWAYS, 1, 0xff)
	gl.StencilMask(0xff)

	transform := linalg.matrix4_translate(types.Vec3{0, 0.5, 0}) * linalg.matrix4_scale_f32(types.Vec3{0.75, 0.75, 0})
	gl.UniformMatrix4fv(gl.GetUniformLocation(single_color_shader, "transform"), 1, false, raw_data(&transform))
	primitives.quad_draw()

	gl.StencilFunc(gl.NOTEQUAL, 1, 0xff)
	gl.StencilMask(0x00)

	gl.UseProgram(single_color_shader)
	transform = linalg.matrix4_translate(types.Vec3{0, 0.5, 0}) * linalg.matrix4_scale_f32(types.Vec3{0.8, 0.8, 0})
	gl.UniformMatrix4fv(gl.GetUniformLocation(single_color_shader, "transform"), 1, false, raw_data(&transform))
	primitives.quad_draw()

	gl.Disable(gl.STENCIL_TEST)
	gl.Enable(gl.DEPTH_TEST)
}

draw_skybox_scene :: proc(scene: render.Scene, skybox_shader, light_shader, texture_shader, single_color_shader: u32) {
	model := linalg.identity(types.TransformMatrix)
	projection := render.camera_get_projection(&camera)
	view := render.camera_get_view(&camera)
	transform := projection * view * model
	mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

	view_without_translate := types.TransformMatrix(types.SubTransformMatrix(view))
	pv := projection * view_without_translate

	// gl.UseProgram(skybox_reflect_shader)
	gl.UseProgram(skybox_refract_shader)

	gl.UniformMatrix4fv(gl.GetUniformLocation(skybox_reflect_shader, "transform"), 1, false, raw_data(&transform))
	gl.UniformMatrix4fv(gl.GetUniformLocation(skybox_reflect_shader, "model"), 1, false, raw_data(&model))
	gl.UniformMatrix3fv(gl.GetUniformLocation(skybox_reflect_shader, "mit"), 1, false, raw_data(&mit))
	gl.Uniform3fv(gl.GetUniformLocation(skybox_reflect_shader, "camera_position"), 1, raw_data(&camera.position))

	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	gl.Enable(gl.DEPTH_TEST)
	gl.BindTexture(gl.TEXTURE_CUBE_MAP, cubemap.texture_id)

	// primitives.cube_draw()
	for _, &mesh in scene.meshes {
		render.mesh_draw(&mesh, single_color_shader)
	}

	gl.DepthFunc(gl.LEQUAL)
	gl.UseProgram(skybox_shader)

	gl.UniformMatrix4fv(gl.GetUniformLocation(skybox_shader, "projection_view"), 1, false, raw_data(&pv))
	primitives.cubemap_draw(&cubemap)

	gl.DepthFunc(gl.LESS)
}

draw_houses :: proc() {
	gl.ClearColor(0, 0, 0, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.UseProgram(house_shader)
	primitives.points_draw()
}

draw_exploded_model :: proc(scene: render.Scene, time: f32) {
	gl.ClearColor(0, 0, 0, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	gl.Enable(gl.DEPTH_TEST)

	gl.UseProgram(explode_shader)

	projection := render.camera_get_projection(&camera)
	view := render.camera_get_view(&camera)
	pv := projection * view
	model := linalg.identity(types.TransformMatrix)
	mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
	transform := pv * model

	gl.UniformMatrix4fv(gl.GetUniformLocation(explode_shader, "transform"), 1, false, raw_data(&transform))
	gl.UniformMatrix4fv(gl.GetUniformLocation(explode_shader, "model"), 1, false, raw_data(&model))
	gl.UniformMatrix3fv(gl.GetUniformLocation(explode_shader, "mit"), 1, false, raw_data(&mit))

	gl.Uniform1f(gl.GetUniformLocation(explode_shader, "time"), time)

	for _, &mesh in scene.meshes {
		render.mesh_draw(&mesh, explode_shader)
	}
}

draw_normals :: proc(scene: render.Scene) {
	draw_scene(scene)

	projection := render.camera_get_projection(&camera)
	view := render.camera_get_view(&camera)
	model := linalg.identity(types.TransformMatrix)
	view_model := view * model
	mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

	gl.UseProgram(normal_shader)
	gl.UniformMatrix4fv(gl.GetUniformLocation(normal_shader, "view_model"), 1, false, raw_data(&view_model))
	gl.UniformMatrix4fv(gl.GetUniformLocation(normal_shader, "projection"), 1, false, raw_data(&projection))
	gl.UniformMatrix3fv(gl.GetUniformLocation(normal_shader, "mit"), 1, false, raw_data(&mit))

	for _, &mesh in scene.meshes {
		render.mesh_draw(&mesh, normal_shader)
	}
}

draw_asteroid_scene :: proc(planet_scene, rock_scene: render.Scene) {
	ensure(planet_shader != 0, "planet shader not initialized")

	planet_center := types.Vec3{0, -3, -55}

	gl.ClearColor(0.1, 0.1, 0.1, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	gl.Enable(gl.DEPTH_TEST)

	projection := render.camera_get_projection(&camera)
	view := render.camera_get_view(&camera)
	pv := projection * view

	{
		model := linalg.matrix4_translate(planet_center)
		model = model * linalg.matrix4_scale_f32(types.Vec3{4, 4, 4})
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
		transform := pv * model

		gl.UseProgram(planet_shader)
		gl.UniformMatrix4fv(gl.GetUniformLocation(planet_shader, "transform"), 1, false, raw_data(&transform))
		gl.UniformMatrix4fv(gl.GetUniformLocation(planet_shader, "model"), 1, false, raw_data(&model))
		gl.UniformMatrix3fv(gl.GetUniformLocation(planet_shader, "mit"), 1, false, raw_data(&mit))

		for _, &mesh in planet_scene.meshes {
			render.mesh_draw(&mesh, planet_shader)
		}
	}

	for model in asteroid_model_transforms {
		model := linalg.matrix4_translate(planet_center) * model
		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
		transform := pv * model

		gl.UniformMatrix4fv(gl.GetUniformLocation(planet_shader, "transform"), 1, false, raw_data(&transform))
		gl.UniformMatrix4fv(gl.GetUniformLocation(planet_shader, "model"), 1, false, raw_data(&model))
		gl.UniformMatrix3fv(gl.GetUniformLocation(planet_shader, "mit"), 1, false, raw_data(&mit))

		for _, &mesh in rock_scene.meshes {
			render.mesh_draw(&mesh, planet_shader)
		}
	}
}

draw_instanced_rects :: proc() {
	gl.UseProgram(instanced_rect_shader)
	primitives.quad_draw_instanced(100, instanced_rect_offset_vbo)
}

distance_squared_from_camera :: proc(v: types.Vec3) -> f32 {
	diff := camera.position - v
	return linalg.dot(diff, diff)
}

distance_order :: proc(lhs, rhs: types.Vec3) -> bool {
	return distance_squared_from_camera(lhs) > distance_squared_from_camera(rhs)
}

set_asteroid_transforms :: proc() {
	radius :: 50
	rotation_axis :: types.Vec3{0.4, 0.6, 0.8}

	for i in 0 ..< NUM_ASTEROIDS {
		angle := f32(i) / f32(NUM_ASTEROIDS) * 360

		translation := types.Vec3 {
			math.sin(angle) * radius + generate_random_displacement(),
			generate_random_displacement() * 0.4,
			math.cos(angle) * radius + generate_random_displacement(),
		}

		scale := f32(rand.int31() % 20) / 100 + 0.05
		rotation := f32(rand.int31() % 360)

		asteroid_model_transforms[i] =
			linalg.matrix4_translate(translation) *
			linalg.matrix4_rotate(rotation, rotation_axis) *
			linalg.matrix4_scale_f32(scale)
	}
}

generate_random_displacement :: proc() -> f32 {
	offset :: 2.5

	// TODO: rewrite using rand.float32
	return f32(rand.int31() % i32(200 * offset)) / 100 - offset
}
