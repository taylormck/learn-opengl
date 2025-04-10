package mtl

import "core:testing"

@(test)
expect_to_get_eof_token :: proc(t: ^testing.T) {
    input := ""

    iter := MaterialParserIter {
        data = input[:],
    }

    actual := iter_get_next_token(&iter)

    testing.expect_value(t, actual, MaterialToken{type = .EOF, value = nil})
}

@(test)
expect_to_get_material_name_tokens :: proc(t: ^testing.T) {
    input := "newmtl Scene_-_Root"
    expected := [?]MaterialToken{MaterialToken{type = .MaterialName}, MaterialToken{type = .String, value = input[7:]}}

    iter := MaterialParserIter {
        data = input,
    }

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_shininess_tokens :: proc(t: ^testing.T) {
    input := "Ns 225.00000"
    expected := [?]MaterialToken{MaterialToken{type = .Shininess}, MaterialToken{type = .Float, value = 225.0}}

    iter := MaterialParserIter {
        data = input,
    }

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_color_tokens :: proc(t: ^testing.T) {
    input := "Ka 1.000000 1.000000 1.000000\nKd 0.800000 0.800000 0.800000\nKs 0.500000 0.500000 0.500000"

    expected := [?]MaterialToken {
        MaterialToken{type = .Ambient},
        MaterialToken{type = .Float, value = 1.0},
        MaterialToken{type = .Float, value = 1.0},
        MaterialToken{type = .Float, value = 1.0},
        MaterialToken{type = .Diffuse},
        MaterialToken{type = .Float, value = 0.8},
        MaterialToken{type = .Float, value = 0.8},
        MaterialToken{type = .Float, value = 0.8},
        MaterialToken{type = .Specular},
        MaterialToken{type = .Float, value = 0.5},
        MaterialToken{type = .Float, value = 0.5},
        MaterialToken{type = .Float, value = 0.5},
    }

    iter := MaterialParserIter {
        data = input,
    }

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}
