package mtl

import "../../render"
import "../../types"
import "../common"
import "core:testing"


@(test)
parse_float_should_parse_float :: proc(t: ^testing.T) {
    input := "225.500000"

    iter := material_iter_init(input)

    expected: f32 = 225.5
    actual, ok := parse_float(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_vec4_should_parse_4_floats :: proc(t: ^testing.T) {
    input := "0.1 0.25 0.5 0.75"

    iter := material_iter_init(input)

    expected := types.Vec4{0.1, 0.25, 0.5, 0.75}
    actual, ok := parse_vec4(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_vec4_should_parse_3_floats_and_imply_1 :: proc(t: ^testing.T) {
    input := "0.1 0.25 0.5"

    iter := material_iter_init(input)

    expected := types.Vec4{0.1, 0.25, 0.5, 1}
    actual, ok := parse_vec4(&iter)

    testing.expect_value(t, actual, expected)
}

@(test)
parse_int_should_parse_int :: proc(t: ^testing.T) {
    input := "2"

    iter := material_iter_init(input)

    expected: i32 = 2
    actual, ok := parse_int(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_string_should_parse_string :: proc(t: ^testing.T) {
    input := "test"

    iter := material_iter_init(input)

    expected := "test"
    actual, ok := parse_string(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_ambient_data :: proc(t: ^testing.T) {
    input := "Ka 0.1 0.25 0.5"

    expected := render.Material {
        ambient = {0.1, 0.25, 0.5, 1},
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_diffuse_data :: proc(t: ^testing.T) {
    input := "Kd 0.1 0.25 0.5"

    expected := render.Material {
        diffuse = {0.1, 0.25, 0.5, 1},
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_specular_data :: proc(t: ^testing.T) {
    input := "Ks 0.1 0.25 0.5"

    expected := render.Material {
        specular = {0.1, 0.25, 0.5, 1},
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_emmisive_data :: proc(t: ^testing.T) {
    input := "Ke 0.1 0.25 0.5"

    expected := render.Material {
        emmisive = {0.1, 0.25, 0.5, 1},
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_all_color_data :: proc(t: ^testing.T) {
    input := "Ka 0.1 0.25 0.5\n" + "Kd 0.1 0.25 0.5\n" + "Ks 0.1 0.25 0.5\n" + "Ke 0.1 0.25 0.5\n"

    expected := render.Material {
        ambient  = {0.1, 0.25, 0.5, 1},
        diffuse  = {0.1, 0.25, 0.5, 1},
        specular = {0.1, 0.25, 0.5, 1},
        emmisive = {0.1, 0.25, 0.5, 1},
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_shininess_coefficient :: proc(t: ^testing.T) {
    input := "Ns 225.000000"

    expected := render.Material {
        shininess = 225,
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

/*
map_Kd diffuse.jpg
map_Bump normal.png
map_Ks specular.jpg
 */

@(test)
parse_material_should_parse_diffuse_map :: proc(t: ^testing.T) {
    input := "map_Kd diffuse.jpg"

    expected := render.Material {
        diffuse_map = "diffuse.jpg",
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_normal_map :: proc(t: ^testing.T) {
    input := "map_Bump normal.png"

    expected := render.Material {
        normal_map = "normal.png",
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_specular_map :: proc(t: ^testing.T) {
    input := "map_Ks specular.jpg"

    expected := render.Material {
        specular_map = "specular.jpg",
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_the_material_name_map :: proc(t: ^testing.T) {
    input := "newmtl Scene_-_Root"

    expected := render.Material {
        name = "Scene_-_Root",
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_all_needed_data :: proc(t: ^testing.T) {
    input :=
        "newmtl Scene_-_Root\n" +
        "Ka 0.1 0.25 0.5\n" +
        "Kd 0.1 0.25 0.5\n" +
        "Ks 0.1 0.25 0.5\n" +
        "Ke 0.1 0.25 0.5\n" +
        "Ns 225.000000\n" +
        "map_Kd diffuse.jpg\n" +
        "map_Bump normal.png\n" +
        "map_Ks specular.jpg\n"

    expected := render.Material {
        name         = "Scene_-_Root",
        ambient      = {0.1, 0.25, 0.5, 1},
        diffuse      = {0.1, 0.25, 0.5, 1},
        specular     = {0.1, 0.25, 0.5, 1},
        emmisive     = {0.1, 0.25, 0.5, 1},
        shininess    = 225,
        diffuse_map  = "diffuse.jpg",
        normal_map   = "normal.png",
        specular_map = "specular.jpg",
    }
    actual, ok := parse_material(input)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_all_needed_data_into_preallocated_memory :: proc(t: ^testing.T) {
    input :=
        "newmtl Scene_-_Root\n" +
        "Ka 0.1 0.25 0.5\n" +
        "Kd 0.1 0.25 0.5\n" +
        "Ks 0.1 0.25 0.5\n" +
        "Ke 0.1 0.25 0.5\n" +
        "Ns 225.000000\n" +
        "map_Kd diffuse.jpg\n" +
        "map_Bump normal.png\n" +
        "map_Ks specular.jpg\n"

    expected := render.Material {
        name         = "Scene_-_Root",
        ambient      = {0.1, 0.25, 0.5, 1},
        diffuse      = {0.1, 0.25, 0.5, 1},
        specular     = {0.1, 0.25, 0.5, 1},
        emmisive     = {0.1, 0.25, 0.5, 1},
        shininess    = 225,
        diffuse_map  = "diffuse.jpg",
        normal_map   = "normal.png",
        specular_map = "specular.jpg",
    }
    actual: render.Material
    ok := parse_material(input, &actual)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_material_should_parse_all_needed_data_into_heap_allocated_memory :: proc(t: ^testing.T) {
    input :=
        "newmtl Scene_-_Root\n" +
        "Ka 0.1 0.25 0.5\n" +
        "Kd 0.1 0.25 0.5\n" +
        "Ks 0.1 0.25 0.5\n" +
        "Ke 0.1 0.25 0.5\n" +
        "Ns 225.000000\n" +
        "map_Kd diffuse.jpg\n" +
        "map_Bump normal.png\n" +
        "map_Ks specular.jpg\n"

    expected := render.Material {
        name         = "Scene_-_Root",
        ambient      = {0.1, 0.25, 0.5, 1},
        diffuse      = {0.1, 0.25, 0.5, 1},
        specular     = {0.1, 0.25, 0.5, 1},
        emmisive     = {0.1, 0.25, 0.5, 1},
        shininess    = 225,
        diffuse_map  = "diffuse.jpg",
        normal_map   = "normal.png",
        specular_map = "specular.jpg",
    }

    actual, ok := parse_material(input, context.allocator)
    defer free(actual)

    testing.expect(t, ok)
    testing.expect_value(t, actual^, expected)
}
