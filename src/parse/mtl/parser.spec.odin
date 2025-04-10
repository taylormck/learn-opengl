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
