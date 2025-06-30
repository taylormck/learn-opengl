package mtl

import "../../render"
import "../../types"
import "../common"
import "core:log"
import "core:testing"


@(test)
parse_float_should_parse_float :: proc(t: ^testing.T) {
	input := "225.500000"

	iter := common.token_iter_init(MaterialToken, input, string_iter_get_next_token)

	expected: f32 = 225.5
	actual, ok := parse_float(&iter)

	testing.expect(t, ok)
	testing.expect_value(t, actual, expected)
}

@(test)
parse_vec4_should_parse_4_floats :: proc(t: ^testing.T) {
	input := "0.1 0.25 0.5 0.75"

	iter := common.token_iter_init(MaterialToken, input, string_iter_get_next_token)

	expected := types.Vec4{0.1, 0.25, 0.5, 0.75}
	actual, ok := parse_vec4(&iter)

	testing.expect(t, ok)
	testing.expect_value(t, actual, expected)
}

@(test)
parse_vec4_should_parse_3_floats_and_imply_1 :: proc(t: ^testing.T) {
	input := "0.1 0.25 0.5"

	iter := common.token_iter_init(MaterialToken, input, string_iter_get_next_token)

	expected := types.Vec4{0.1, 0.25, 0.5, 1}
	actual, _ := parse_vec4(&iter)

	testing.expect_value(t, actual, expected)
}

@(test)
parse_int_should_parse_int :: proc(t: ^testing.T) {
	input := "2"

	iter := common.token_iter_init(MaterialToken, input, string_iter_get_next_token)

	expected: i32 = 2
	actual, ok := parse_int(&iter)

	testing.expect(t, ok)
	testing.expect_value(t, actual, expected)
}

@(test)
parse_string_should_parse_string :: proc(t: ^testing.T) {
	input := "test"

	iter := common.token_iter_init(MaterialToken, input, string_iter_get_next_token)

	expected := "test"
	actual, ok := parse_string(&iter)
	defer if ok do delete(actual)

	testing.expect(t, ok)
	testing.expect_value(t, actual, expected)
}

@(test)
parse_materials_should_return_not_ok_when_there_is_no_material_name :: proc(t: ^testing.T) {
	input := "Ka 0.1 0.25 0.5"

	// Wrap the logger with an empty multi-logger to prevent the log statements from printing to the console.
	context.logger = log.create_multi_logger()
	defer log.destroy_multi_logger(context.logger)

	_, ok := parse_materials(input)

	testing.expect(t, !ok)
}

@(test)
parse_material_should_parse_ambient_data :: proc(t: ^testing.T) {
	input := "newmtl mymat\n" + "Ka 0.1 0.25 0.5"

	expected := render.Material {
		name    = "mymat",
		ambient = {0.1, 0.25, 0.5, 1},
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["mymat"], expected)
}

@(test)
parse_material_should_parse_diffuse_data :: proc(t: ^testing.T) {
	input := "newmtl mymat\n" + "Kd 0.1 0.25 0.5"

	expected := render.Material {
		name    = "mymat",
		diffuse = {0.1, 0.25, 0.5, 1},
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["mymat"], expected)
}

@(test)
parse_material_should_parse_specular_data :: proc(t: ^testing.T) {
	input := "newmtl mymat\n" + "Ks 0.1 0.25 0.5"

	expected := render.Material {
		name     = "mymat",
		specular = {0.1, 0.25, 0.5, 1},
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["mymat"], expected)
}

@(test)
parse_material_should_parse_emissive_data :: proc(t: ^testing.T) {
	input := "newmtl mymat\n" + "Ke 0.1 0.25 0.5"

	expected := render.Material {
		name     = "mymat",
		emissive = {0.1, 0.25, 0.5, 1},
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["mymat"], expected)
}

@(test)
parse_material_should_parse_all_color_data :: proc(t: ^testing.T) {
	input := "newmtl mymat\n" + "Ka 0.1 0.25 0.5\n" + "Kd 0.1 0.25 0.5\n" + "Ks 0.1 0.25 0.5\n" + "Ke 0.1 0.25 0.5\n"

	expected := render.Material {
		name     = "mymat",
		ambient  = {0.1, 0.25, 0.5, 1},
		diffuse  = {0.1, 0.25, 0.5, 1},
		specular = {0.1, 0.25, 0.5, 1},
		emissive = {0.1, 0.25, 0.5, 1},
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["mymat"], expected)
}

@(test)
parse_material_should_parse_shininess_coefficient :: proc(t: ^testing.T) {
	input := "newmtl mymat\n" + "Ns 225.000000"

	expected := render.Material {
		name      = "mymat",
		shininess = 225,
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["mymat"], expected)
}

@(test)
parse_material_should_parse_diffuse_map :: proc(t: ^testing.T) {
	input := "newmtl mymat\n" + "map_Kd diffuse.jpg"

	expected := render.Material {
		name        = "mymat",
		diffuse_map = "diffuse.jpg",
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["mymat"], expected)
}

@(test)
parse_material_should_parse_normal_map :: proc(t: ^testing.T) {
	input := "newmtl mymat\n" + "map_Bump normal.png"

	expected := render.Material {
		name       = "mymat",
		normal_map = "normal.png",
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["mymat"], expected)
}

@(test)
parse_material_should_parse_specular_map :: proc(t: ^testing.T) {
	input := "newmtl mymat\n" + "map_Ks specular.jpg"

	expected := render.Material {
		name         = "mymat",
		specular_map = "specular.jpg",
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["mymat"], expected)
}

@(test)
parse_material_should_parse_the_material_name_map :: proc(t: ^testing.T) {
	input := "newmtl Scene_-_Root"

	expected := render.Material {
		name = "Scene_-_Root",
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["Scene_-_Root"], expected)
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
		emissive     = {0.1, 0.25, 0.5, 1},
		shininess    = 225,
		diffuse_map  = "diffuse.jpg",
		normal_map   = "normal.png",
		specular_map = "specular.jpg",
	}

	actual, ok := parse_materials(input)
	defer delete(actual)
	defer for _, &material in actual do render.material_free(&material)

	testing.expect(t, ok)
	testing.expect_value(t, actual["Scene_-_Root"], expected)
}
