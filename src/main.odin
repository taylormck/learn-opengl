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
import "shaders"
import "types"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "window"

INITIAL_WIDTH :: 800
INITIAL_HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5
NUM_SAMPLES :: 4

fbo, fb_texture, rbo: u32
ms_fbo, ms_fb_texture, ms_rbo: u32
cubemap: primitives.Cubemap

NUM_ASTEROIDS :: 1000000
PLANET_CENTER :: types.Vec3{0, -3, -55}
asteroid_model_transforms: [dynamic]types.TransformMatrix

instanced_rect_offset_vbo: u32
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
	glfw.WindowHint(glfw.SAMPLES, NUM_SAMPLES)

	window_handle := glfw.CreateWindow(INITIAL_WIDTH, INITIAL_HEIGHT, "Renderer", nil, nil)
	defer glfw.DestroyWindow(window_handle)

	if window_handle == nil {
		panic("GLFW failed to open the window.")
	}

	glfw.MakeContextCurrent(window_handle)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	gl.Viewport(0, 0, INITIAL_WIDTH, INITIAL_HEIGHT)
	glfw.SetFramebufferSizeCallback(window_handle, framebuffer_size_callback)

	glfw.SetInputMode(window_handle, glfw.CURSOR, glfw.CURSOR_DISABLED)
	glfw.SetCursorPosCallback(window_handle, mouse_callback)
	glfw.SetScrollCallback(window_handle, scroll_callback)

	window.width = INITIAL_WIDTH
	window.height = INITIAL_HEIGHT

	init_input()

	// index := 0
	// offset: f32 = 0.1
	//
	// for y := -10; y < 10; y += 2 {
	// 	for x := -10; x < 10; x += 2 {
	// 		translation := &instanced_rect_translations[index]
	// 		translation.x = f32(x) / 10.0 + offset
	// 		translation.y = f32(y) / 10.0 + offset
	// 		index += 1
	// 	}
	// }
	//
	// gl.GenBuffers(1, &instanced_rect_offset_vbo)
	// gl.BindBuffer(gl.ARRAY_BUFFER, instanced_rect_offset_vbo)
	// gl.BufferData(gl.ARRAY_BUFFER, size_of(instanced_rect_translations), &instanced_rect_translations, gl.STATIC_DRAW)

	// planet_scene :=
	// 	obj.load_scene_from_file_obj("models/planet", "planet.obj") or_else panic("Failed to load planet model.")
	// defer render.scene_destroy(&planet_scene)
	//
	// for _, &mesh in planet_scene.meshes do render.mesh_send_to_gpu(&mesh)
	// defer for _, &mesh in planet_scene.meshes do render.mesh_gpu_free(&mesh)
	//
	// rock_scene := obj.load_scene_from_file_obj("models/rock", "rock.obj") or_else panic("Failed to load rock model.")
	// defer render.scene_destroy(&rock_scene)
	//
	// asteroid_model_transforms = make([dynamic]types.TransformMatrix, NUM_ASTEROIDS)
	// defer delete(asteroid_model_transforms)
	// set_asteroid_transforms()
	//
	// for _, &mesh in rock_scene.meshes {
	// 	render.mesh_send_to_gpu(&mesh)
	// 	render.mesh_send_transforms_to_gpu(&mesh, asteroid_model_transforms[:])
	// }
	// defer for _, &mesh in rock_scene.meshes do render.mesh_gpu_free(&mesh)

	// gl.GenFramebuffers(1, &ms_fbo)
	// defer gl.DeleteFramebuffers(1, &ms_fbo)
	// gl.BindFramebuffer(gl.FRAMEBUFFER, ms_fbo)
	//
	// gl.GenTextures(1, &ms_fb_texture)
	// gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, ms_fb_texture)
	// gl.TexImage2DMultisample(gl.TEXTURE_2D_MULTISAMPLE, NUM_SAMPLES, gl.RGB, INITIAL_WIDTH, INITIAL_HEIGHT, gl.TRUE)
	// gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, 0)
	//
	// gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D_MULTISAMPLE, ms_fb_texture, 0)
	//
	// gl.GenRenderbuffers(1, &ms_rbo)
	// gl.BindRenderbuffer(gl.RENDERBUFFER, ms_rbo)
	// gl.RenderbufferStorageMultisample(gl.RENDERBUFFER, NUM_SAMPLES, gl.DEPTH24_STENCIL8, INITIAL_WIDTH, INITIAL_HEIGHT)
	// gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
	//
	// gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, ms_rbo)
	//
	// if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE do panic("Multisample Framebuffer incomplete!")
	// gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	gl.Enable(gl.MULTISAMPLE)

	current_tableau := tableaus[.Chapter_04_08_01_advanced_glsl_ubo]

	if current_tableau.init != nil do current_tableau.init()
	defer if current_tableau.teardown != nil do current_tableau.teardown()
	defer shaders.delete_shaders()

	prev_time := glfw.GetTime()

	for !glfw.WindowShouldClose(window_handle) {
		new_time := glfw.GetTime()
		delta := new_time - prev_time

		glfw.PollEvents()
		process_input(window_handle, delta)

		if current_tableau.update != nil do current_tableau.update(delta)

		clear_input()

		current_tableau.draw()

		glfw.SwapBuffers(window_handle)
		prev_time = new_time
	}
}

// draw_houses :: proc() {
// 	gl.ClearColor(0, 0, 0, 1)
// 	gl.Clear(gl.COLOR_BUFFER_BIT)
//
// 	house_shader := tableau.shaders[.House]
// 	gl.UseProgram(house_shader)
// 	primitives.points_draw()
// }
//
// draw_exploded_model :: proc(scene: render.Scene, time: f32) {
// 	gl.ClearColor(0, 0, 0, 1)
// 	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
// 	gl.Enable(gl.DEPTH_TEST)
//
// 	explode_shader := tableau.shaders[.Explode]
// 	gl.UseProgram(explode_shader)
//
// 	projection := render.camera_get_projection(&camera)
// 	view := render.camera_get_view(&camera)
// 	pv := projection * view
// 	model := linalg.identity(types.TransformMatrix)
// 	mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
// 	transform := pv * model
//
// 	gl.UniformMatrix4fv(gl.GetUniformLocation(explode_shader, "transform"), 1, false, raw_data(&transform))
// 	gl.UniformMatrix4fv(gl.GetUniformLocation(explode_shader, "model"), 1, false, raw_data(&model))
// 	gl.UniformMatrix3fv(gl.GetUniformLocation(explode_shader, "mit"), 1, false, raw_data(&mit))
//
// 	gl.Uniform1f(gl.GetUniformLocation(explode_shader, "time"), time)
//
// 	for _, &mesh in scene.meshes {
// 		render.mesh_draw(&mesh, explode_shader)
// 	}
// }

// draw_normals :: proc(scene: render.Scene) {
// 	draw_scene(scene)
//
// 	projection := render.camera_get_projection(&camera)
// 	view := render.camera_get_view(&camera)
// 	model := linalg.identity(types.TransformMatrix)
// 	view_model := view * model
// 	mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
//
// 	normal_shader := tableau.shaders[.Normal]
// 	gl.UseProgram(normal_shader)
// 	gl.UniformMatrix4fv(gl.GetUniformLocation(normal_shader, "view_model"), 1, false, raw_data(&view_model))
// 	gl.UniformMatrix4fv(gl.GetUniformLocation(normal_shader, "projection"), 1, false, raw_data(&projection))
// 	gl.UniformMatrix3fv(gl.GetUniformLocation(normal_shader, "mit"), 1, false, raw_data(&mit))
//
// 	for _, &mesh in scene.meshes {
// 		render.mesh_draw(&mesh, normal_shader)
// 	}
// }
//
// draw_instanced_rects :: proc() {
// 	gl.UseProgram(tableau.shaders[.InstancedRect])
// 	primitives.quad_draw_instanced(100, instanced_rect_offset_vbo)
// }

// draw_asteroid_scene :: proc(planet_scene, rock_scene: render.Scene) {
// 	planet_shader := tableau.shaders[.Planet]
// 	asteroid_shader := tableau.shaders[.Asteroid]
//
// 	ensure(planet_shader != 0, "planet shader not initialized")
// 	ensure(asteroid_shader != 0, "asteroid_shader shader not initialized")
//
// 	gl.ClearColor(0.1, 0.1, 0.1, 1)
// 	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
// 	gl.Enable(gl.DEPTH_TEST)
//
// 	projection := render.camera_get_projection(&camera)
// 	view := render.camera_get_view(&camera)
// 	pv := projection * view
//
// 	{
// 		model := linalg.matrix4_translate(PLANET_CENTER)
// 		model = model * linalg.matrix4_scale_f32(types.Vec3{4, 4, 4})
// 		mit := types.SubTransformMatrix(linalg.inverse_transpose(model))
// 		transform := pv * model
//
// 		gl.UseProgram(planet_shader)
// 		gl.UniformMatrix4fv(gl.GetUniformLocation(planet_shader, "transform"), 1, false, raw_data(&transform))
// 		gl.UniformMatrix4fv(gl.GetUniformLocation(planet_shader, "model"), 1, false, raw_data(&model))
// 		gl.UniformMatrix3fv(gl.GetUniformLocation(planet_shader, "mit"), 1, false, raw_data(&mit))
//
// 		for _, &mesh in planet_scene.meshes {
// 			render.mesh_draw(&mesh, planet_shader)
// 		}
// 	}
//
// 	{
// 		gl.UseProgram(asteroid_shader)
// 		gl.UniformMatrix4fv(gl.GetUniformLocation(asteroid_shader, "pv"), 1, false, raw_data(&pv))
//
// 		for _, &mesh in rock_scene.meshes {
// 			render.mesh_draw_instanced(&mesh, asteroid_shader, NUM_ASTEROIDS)
// 		}
//
// 		gl.BindVertexArray(0)
// 	}
// }

// draw_green_box :: proc() {
// 	gl.BindFramebuffer(gl.FRAMEBUFFER, ms_fbo)
//
// 	gl.ClearColor(0.1, 0.2, 0.3, 1)
// 	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
// 	gl.Enable(gl.DEPTH_TEST)
//
// 	model := linalg.matrix4_rotate_f32(math.PI / 4, types.Vec3{1, 1, 1})
// 	projection := render.camera_get_projection(&camera)
// 	view := render.camera_get_view(&camera)
// 	transform := projection * view * model
//
// 	gl.UseProgram(tableau.shaders[.SingleColor])
// 	gl.UniformMatrix4fv(
// 		gl.GetUniformLocation(tableau.shaders[.SingleColor], "transform"),
// 		1,
// 		false,
// 		raw_data(&transform),
// 	)
// 	primitives.cube_draw()
//
// 	gl.BindFramebuffer(gl.READ_FRAMEBUFFER, ms_fbo)
// 	gl.BindFramebuffer(gl.DRAW_FRAMEBUFFER, fbo)
// 	gl.BlitFramebuffer(
// 		0,
// 		0,
// 		window_width,
// 		window_height,
// 		0,
// 		0,
// 		window_width,
// 		window_height,
// 		gl.COLOR_BUFFER_BIT,
// 		gl.NEAREST,
// 	)
//
// 	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
// 	gl.ClearColor(0.1, 0.2, 0.3, 1)
// 	gl.Clear(gl.COLOR_BUFFER_BIT)
// 	gl.Disable(gl.DEPTH_TEST)
// 	gl.BindTexture(gl.TEXTURE_2D, fb_texture)
//
// 	gl.UseProgram(tableau.shaders[.Invert])
// 	primitives.full_screen_draw()
// }

framebuffer_size_callback :: proc "cdecl" (window_handle: glfw.WindowHandle, width, height: i32) {
	context = runtime.default_context()
	window.width = width
	window.height = height

	gl.Viewport(0, 0, width, height)

	// gl.BindTexture(gl.TEXTURE_2D, fb_texture)
	// defer gl.BindTexture(gl.TEXTURE_2D, 0)
	// gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, nil)
	//
	// gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
	// defer gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
	// gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, width, height)
	//
	// gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, ms_fb_texture)
	// defer gl.BindTexture(gl.TEXTURE_2D_MULTISAMPLE, 0)
	// gl.TexImage2DMultisample(gl.TEXTURE_2D_MULTISAMPLE, NUM_SAMPLES, gl.RGB, width, height, gl.TRUE)
	//
	// gl.BindRenderbuffer(gl.RENDERBUFFER, ms_rbo)
	// defer gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
	// gl.RenderbufferStorageMultisample(gl.RENDERBUFFER, NUM_SAMPLES, gl.DEPTH24_STENCIL8, width, height)
}

// set_asteroid_transforms :: proc() {
// 	radius :: 50
// 	rotation_axis :: types.Vec3{0.4, 0.6, 0.8}
// 	scale_multiple: f32 : 1.0 / 10
//
// 	for i in 0 ..< NUM_ASTEROIDS {
// 		angle := f32(i) / f32(NUM_ASTEROIDS) * math.TAU
//
// 		translation :=
// 			types.Vec3 {
// 				math.sin(angle) * radius + generate_random_displacement(),
// 				generate_random_displacement() * 0.1,
// 				math.cos(angle) * radius + generate_random_displacement(),
// 			} +
// 			PLANET_CENTER
//
// 		scale := rand.float32_exponential(10) * scale_multiple + 0.005
// 		rotation := rand.float32() * math.TAU
//
// 		asteroid_model_transforms[i] =
// 			linalg.matrix4_translate(translation) *
// 			linalg.matrix4_rotate(rotation, rotation_axis) *
// 			linalg.matrix4_scale_f32(scale)
// 	}
// }
//
// generate_random_displacement :: proc() -> f32 {
// 	offset :: 10.0
//
// 	return rand.float32_normal(offset, 5.0) - offset
// }
