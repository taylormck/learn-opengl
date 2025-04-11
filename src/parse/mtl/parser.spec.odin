package mtl

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
