package obj

import "../../render"
import "../../types"
import "../common"
import "core:log"
import "core:testing"


@(test)
parse_float_should_parse_float :: proc(t: ^testing.T) {
    input := "225.500000"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected: f32 = 225.5
    actual, ok := parse_float(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_vec2_should_parse_2_floats :: proc(t: ^testing.T) {
    input := "0.1 0.25"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected := types.Vec2{0.1, 0.25}
    actual, ok := parse_vec2(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_vec3_should_parse_3_floats :: proc(t: ^testing.T) {
    input := "0.1 0.25 0.5"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected := types.Vec3{0.1, 0.25, 0.5}
    actual, ok := parse_vec3(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_vec4_should_parse_4_floats :: proc(t: ^testing.T) {
    input := "0.1 0.25 0.5 0.75"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected := types.Vec4{0.1, 0.25, 0.5, 0.75}
    actual, ok := parse_vec4(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}


@(test)
parse_int_should_parse_int :: proc(t: ^testing.T) {
    input := "2"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected: i32 = 2
    actual, ok := parse_int(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_string_should_parse_string :: proc(t: ^testing.T) {
    input := "test"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected := "test"
    actual, ok := parse_string(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_string_should_parse_material_file_name :: proc(t: ^testing.T) {
    input := "mtllib test.mtl"

    materials: [dynamic]string
    defer delete(materials)

    append(&materials, "test.mtl")

    expected := render.Scene {
        materials = materials,
    }

    actual, ok := parse_obj(input)
    defer render.scene_destroy(&actual)

    testing.expect(t, ok)
    expect_scene_match(t, &actual, &expected)
}

@(test)
parse_string_should_parse_vertex :: proc(t: ^testing.T) {
    input := "v 1.0 1.0 1.0"

    vertices: [dynamic]types.Vec3
    defer delete(vertices)

    append(&vertices, types.Vec3{1.0, 1.0, 1.0})

    expected := render.Scene {
        vertices = vertices,
    }

    actual, ok := parse_obj(input)
    defer render.scene_destroy(&actual)

    testing.expect(t, ok)
    expect_scene_match(t, &actual, &expected)
}

@(test)
parse_string_should_parse_texture_coordinates :: proc(t: ^testing.T) {
    input := "vt 1.0 1.0"

    texture_coordinates: [dynamic]types.Vec2
    defer delete(texture_coordinates)

    append(&texture_coordinates, types.Vec2{1.0, 1.0})

    expected := render.Scene {
        texture_coordinates = texture_coordinates,
    }

    actual, ok := parse_obj(input)
    defer render.scene_destroy(&actual)

    testing.expect(t, ok)
    expect_scene_match(t, &actual, &expected)
}

@(test)
parse_string_should_parse_vertex_normal :: proc(t: ^testing.T) {
    input := "vn 0.0001 0.9989 0.0473"

    normals: [dynamic]types.Vec3
    defer delete(normals)

    append(&normals, types.Vec3{0.0001, 0.9989, 0.0473})

    expected := render.Scene {
        normals = normals,
    }

    actual, ok := parse_obj(input)
    defer render.scene_destroy(&actual)

    testing.expect(t, ok)
    expect_scene_match(t, &actual, &expected)
}

expect_scene_match :: proc(t: ^testing.T, actual, expected: ^render.Scene) {
    testing.expect_value(t, len(actual.materials), len(expected.materials))
    for i in 0 ..< len(expected.materials) {
        testing.expect_value(t, actual.materials[i], expected.materials[i])
    }

    testing.expect_value(t, len(actual.meshes), len(expected.meshes))
    for i in 0 ..< len(expected.meshes) {
        testing.expect_value(t, actual.meshes[i], expected.meshes[i])
    }

    testing.expect_value(t, len(actual.vertices), len(expected.vertices))
    for i in 0 ..< len(expected.vertices) {
        testing.expect_value(t, actual.vertices[i], expected.vertices[i])
    }

    testing.expect_value(t, len(actual.texture_coordinates), len(expected.texture_coordinates))
    for i in 0 ..< len(expected.texture_coordinates) {
        testing.expect_value(t, actual.texture_coordinates[i], expected.texture_coordinates[i])
    }

    testing.expect_value(t, len(actual.normals), len(expected.normals))
    for i in 0 ..< len(expected.normals) {
        testing.expect_value(t, actual.normals[i], expected.normals[i])
    }
}
