package main

import "base:runtime"
import "core:log"
import "core:math"
import "core:math/linalg"
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
	far          = 100,
	speed        = 5,
}

marble_texture, metal_texture, grass_texture, window_texture: render.Texture

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

	mesh_shader :=
		gl.load_shaders_source(
			#load("../shaders/vert/pos_tex_normal_transform.vert"),
			#load("../shaders/frag/phong_material_sampled_multilights.frag"),
		) or_else panic("Failed to load the shader")
	defer gl.DeleteProgram(mesh_shader)

	texture_shader :=
		gl.load_shaders_source(
			#load("../shaders/vert/pos_tex_transform.vert"),
			#load("../shaders/frag/single_tex.frag"),
		) or_else panic("Failed to load the shader")
	defer gl.DeleteProgram(texture_shader)

	// depth_shader :=
	//     gl.load_shaders_source(
	//         #load("../shaders/vert/pos_tex_normal_transform.vert"),
	//         #load("../shaders/frag/depth.frag"),
	//     ) or_else panic("Failed to load the shader")
	// defer gl.DeleteProgram(depth_shader)

	single_color_shader :=
		gl.load_shaders_source(
			#load("../shaders/vert/pos_tex_normal_transform.vert"),
			#load("../shaders/frag/single_color.frag"),
		) or_else panic("Failed to load the shader")
	defer gl.DeleteProgram(single_color_shader)

	light_shader :=
		gl.load_shaders_source(
			#load("../shaders/vert/pos_transform.vert"),
			#load("../shaders/frag/light_color.frag"),
		) or_else panic("Failed to load the light shader")
	defer gl.DeleteProgram(light_shader)

	scene :=
		obj.load_scene_from_file_obj("models/backpack", "backpack.obj") or_else panic("Failed to load backpack model.")
	defer render.scene_destroy(&scene)

	for _, &mesh in scene.meshes do render.mesh_send_to_gpu(&mesh)
	defer for _, &mesh in scene.meshes do render.mesh_gpu_free(&mesh)

	primitives.cube_send_to_gpu()
	defer primitives.cube_clear_from_gpu()

	primitives.quad_send_to_gpu()
	defer primitives.quad_clear_from_gpu()

	primitives.cross_imposter_send_to_gpu()
	defer primitives.cross_imposter_clear_from_gpu()

	gl.UseProgram(mesh_shader)

	render.directional_light_set_uniform(&directional_light, mesh_shader)

	for &point_light, i in point_lights {
		render.point_light_array_set_uniform(&point_light, mesh_shader, u32(i))
	}

	metal_texture = render.prepare_texture("textures/metal.png", 3, .Diffuse, true)
	marble_texture = render.prepare_texture("textures/marble.jpg", 3, .Diffuse, true)
	grass_texture = render.prepare_texture("textures/grass.png", 4, .Diffuse, true)
	window_texture = render.prepare_texture("textures/blending_transparent_window.png", 4, .Diffuse, true)

	gl.BindTexture(gl.TEXTURE_2D, grass_texture.id)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	gl.BindTexture(gl.TEXTURE_2D, window_texture.id)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	gl.BindTexture(gl.TEXTURE_2D, 0)

	prev_time := f32(glfw.GetTime())

	for !glfw.WindowShouldClose(window) {
		new_time := f32(glfw.GetTime())
		delta := new_time - prev_time

		glfw.PollEvents()
		process_input(window, delta)

		// draw_backpack_scene(scene, light_shader, mesh_shader, single_color_shader)
		draw_block_scene(scene, light_shader, texture_shader, single_color_shader)

		glfw.SwapBuffers(window)
		gl.BindVertexArray(0)
		prev_time = new_time
	}
}

framebuffer_size_callback :: proc "cdecl" (window: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()

	gl.Viewport(0, 0, width, height)
	camera.aspect_ratio = f32(width) / f32(height)
}

draw_backpack_scene :: proc(scene: render.Scene, light_shader, mesh_shader, single_color_shader: u32) {
	gl.Enable(gl.STENCIL_TEST)
	gl.StencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)

	gl.ClearColor(0.1, 0.2, 0.3, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT)
	gl.StencilMask(0x00)
	gl.Enable(gl.DEPTH_TEST)
	gl.StencilFunc(gl.ALWAYS, 1, 0xff)
	gl.StencilMask(0xff)

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


draw_block_scene :: proc(scene: render.Scene, light_shader, texture_shader, single_color_shader: u32) {
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

distance_squared_from_camera :: proc(v: types.Vec3) -> f32 {
	diff := camera.position - v
	return linalg.dot(diff, diff)
}

distance_order :: proc(lhs, rhs: types.Vec3) -> bool {
	return distance_squared_from_camera(lhs) > distance_squared_from_camera(rhs)
}
