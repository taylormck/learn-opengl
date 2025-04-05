package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:time"
import "mesh"
import "render"
import "types"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "vendor:stb/image"

WIDTH :: 800
HEIGHT :: 600

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

CUBE_POSITIONS :: [?]types.Vec3 {
    {0, 0, 0},
    {2, 5, -15},
    {-1.5, -2.2, -2.5},
    {-3.8, -2, -12.3},
    {2.4, -0.4, -3.5},
    {-1.7, 3, -7.5},
    {1.3, -2, -2.5},
    {1.5, 2, -2.5},
    {1.5, 0.2, -1.5},
    {-1.3, 1, -1.5},
}

point_light := render.PointLight {
    position  = {1.2, 1, 2},
    ambient   = {0.2, 0.2, 0.2},
    diffuse   = {0.5, 0.5, 0.5},
    specular  = {1, 1, 1},
    constant  = 1,
    linear    = 0.09,
    quadratic = 0.032,
}

directional_light := render.DirectionalLight {
    direction = {-0.2, -1, 0.3},
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

    window := glfw.CreateWindow(WIDTH, HEIGHT, "Hello", nil, nil)
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

    cube_shader :=
        gl.load_shaders_source(
            #load("../shaders/vert/pos_tex_normal_transform.vert"),
            #load("../shaders/frag/phong_material_sampled_multilights.frag"),
        ) or_else panic("Failed to load the shader")

    light_shader :=
        gl.load_shaders_source(
            #load("../shaders/vert/pos_transform.vert"),
            #load("../shaders/frag/light_color.frag"),
        ) or_else panic("Failed to load the light shader")

    light_cube_vao, cube_vao, vbo: u32
    gl.GenVertexArrays(1, &cube_vao)
    defer gl.DeleteVertexArrays(1, &cube_vao)

    gl.GenVertexArrays(1, &light_cube_vao)
    defer gl.DeleteVertexArrays(1, &light_cube_vao)

    gl.GenBuffers(1, &vbo)
    defer gl.DeleteBuffers(1, &vbo)

    mesh.cube_send_to_gpu(cube_vao, vbo)
    mesh.cube_send_to_gpu(light_cube_vao, vbo)

    gl.UseProgram(cube_shader)

    box_texture_ids: [2]u32
    gl.GenTextures(2, raw_data(box_texture_ids[:]))
    defer gl.DeleteTextures(2, raw_data(box_texture_ids[:]))

    diffuse_map := prepare_texture(
        path = "textures/container2.png",
        channels = 4,
        shader_program = cube_shader,
        texture_id = box_texture_ids[0],
        gl_texture = gl.TEXTURE0,
    )
    defer image.image_free(diffuse_map.buffer)

    spec_map := prepare_texture(
        path = "textures/container2_specular.png",
        channels = 4,
        shader_program = cube_shader,
        texture_id = box_texture_ids[1],
        gl_texture = gl.TEXTURE1,
    )
    defer image.image_free(spec_map.buffer)

    material := render.MaterialSampled {
        diffuse   = box_texture_ids[0],
        specular  = box_texture_ids[1],
        shininess = 64,
    }

    render.material_sampled_set_uniform(&material, cube_shader)
    render.point_light_set_uniform(&point_light, cube_shader)
    render.directional_light_set_uniform(&directional_light, cube_shader)

    gl.Enable(gl.DEPTH_TEST)

    prev_time := f32(glfw.GetTime())

    for !glfw.WindowShouldClose(window) {
        new_time := f32(glfw.GetTime())
        delta := new_time - prev_time

        glfw.PollEvents()
        process_input(window, delta)

        gl.ClearColor(0.1, 0.2, 0.3, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        projection := render.camera_get_projection(&camera)
        view := render.camera_get_view(&camera)
        pv := projection * view

        gl.BindVertexArray(light_cube_vao)
        gl.UseProgram(light_shader)

        {
            light_color := WHITE
            model := linalg.matrix4_translate(point_light.position)
            model *= linalg.matrix4_scale_f32({0.2, 0.2, 0.2})
            transform := pv * model

            gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader, "transform"), 1, false, raw_data(&transform))
            gl.Uniform3fv(gl.GetUniformLocation(light_shader, "light_color"), 1, raw_data(&light_color))
            mesh.cube_draw(light_cube_vao)
        }

        gl.BindVertexArray(cube_vao)

        gl.UseProgram(cube_shader)
        gl.Uniform3fv(gl.GetUniformLocation(cube_shader, "view_position"), 1, raw_data(&camera.position))

        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, box_texture_ids[0])

        gl.ActiveTexture(gl.TEXTURE1)
        gl.BindTexture(gl.TEXTURE_2D, box_texture_ids[1])

        spot_light.position = camera.position
        spot_light.direction = camera.direction
        render.spot_light_set_uniform(&spot_light, cube_shader)

        for position, i in CUBE_POSITIONS {
            model := linalg.matrix4_translate(position)

            angle: f32 = linalg.to_radians(20 * f32(i))
            if i % 3 == 0 do angle += new_time

            model *= linalg.matrix4_rotate(angle, types.Vec3{1, 0.3, 0.5})
            mit := types.SubTransformMatrix(linalg.inverse_transpose(model))

            transform := pv * model
            gl.UniformMatrix4fv(gl.GetUniformLocation(cube_shader, "transform"), 1, false, raw_data(&transform))
            gl.UniformMatrix4fv(gl.GetUniformLocation(cube_shader, "model"), 1, false, raw_data(&model))
            gl.UniformMatrix3fv(gl.GetUniformLocation(cube_shader, "mit"), 1, false, raw_data(&mit))
            mesh.cube_draw(cube_vao)
        }

        glfw.SwapBuffers(window)
        gl.BindVertexArray(0)
        prev_time = new_time
    }
}

framebuffer_size_callback :: proc "cdecl" (window: glfw.WindowHandle, width, height: i32) {
    gl.Viewport(0, 0, width, height)
    camera.aspect_ratio = f32(width) / f32(height)
}
