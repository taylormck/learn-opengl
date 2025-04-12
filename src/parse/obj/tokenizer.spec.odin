package obj

import "../common"
import "core:testing"

@(test)
obj_tokenizer_should_get_eof_token :: proc(t: ^testing.T) {
    input := ""

    iter := common.string_iter_init(input)

    actual := string_iter_get_next_token(&iter)

    testing.expect_value(t, actual, ObjToken{type = .EOF, value = nil})
}

@(test)
obj_tokenizer_should_get_string_tokens :: proc(t: ^testing.T) {
    input := "foo  bar\n"

    expected := [?]ObjToken {
        ObjToken{type = .String, value = "foo"},
        ObjToken{type = .String, value = "bar"},
        ObjToken{type = .EOF},
    }

    iter := common.string_iter_init(input)

    for expected_value in expected {
        actual := string_iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
obj_tokenizer_should_get_int_tokens :: proc(t: ^testing.T) {
    input := "1 2 3\n"

    expected := [?]ObjToken {
        ObjToken{type = .Integer, value = 1},
        ObjToken{type = .Integer, value = 2},
        ObjToken{type = .Integer, value = 3},
        ObjToken{type = .EOF},
    }

    iter := common.string_iter_init(input)

    for expected_value in expected {
        actual := string_iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
obj_tokenizer_should_get_float_tokens :: proc(t: ^testing.T) {
    input := "1.0 0.2 3.14\n"

    expected := [?]ObjToken {
        ObjToken{type = .Float, value = 1.0},
        ObjToken{type = .Float, value = 0.2},
        ObjToken{type = .Float, value = 3.14},
        ObjToken{type = .EOF},
    }

    iter := common.string_iter_init(input)

    for expected_value in expected {
        actual := string_iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
obj_tokenizer_should_get_slash_tokens :: proc(t: ^testing.T) {
    input := "/ 1/2/3\n"

    expected := [?]ObjToken {
        ObjToken{type = .Slash},
        ObjToken{type = .Integer, value = 1},
        ObjToken{type = .Slash},
        ObjToken{type = .Integer, value = 2},
        ObjToken{type = .Slash},
        ObjToken{type = .Integer, value = 3},
        ObjToken{type = .EOF},
    }

    iter := common.string_iter_init(input)

    for expected_value in expected {
        actual := string_iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
obj_tokenizer_should_get_vertex_tokens :: proc(t: ^testing.T) {
    input := "v 1.0 0.2 3.14\n"

    expected := [?]ObjToken {
        ObjToken{type = .Vertex},
        ObjToken{type = .Float, value = 1.0},
        ObjToken{type = .Float, value = 0.2},
        ObjToken{type = .Float, value = 3.14},
        ObjToken{type = .EOF},
    }

    iter := common.string_iter_init(input)

    for expected_value in expected {
        actual := string_iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
obj_tokenizer_should_get_texture_tokens :: proc(t: ^testing.T) {
    input := "vt 0.8 0.2\n"

    expected := [?]ObjToken {
        ObjToken{type = .TextureCoordinates},
        ObjToken{type = .Float, value = 0.8},
        ObjToken{type = .Float, value = 0.2},
        ObjToken{type = .EOF},
    }

    iter := common.string_iter_init(input)

    for expected_value in expected {
        actual := string_iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
obj_tokenizer_should_get_vertex_normal_tokens :: proc(t: ^testing.T) {
    input := "vn 0.0164 -0.046 0.9988\n"

    expected := [?]ObjToken {
        ObjToken{type = .VertexNormal},
        ObjToken{type = .Float, value = 0.0164},
        ObjToken{type = .Float, value = -0.046},
        ObjToken{type = .Float, value = 0.9988},
        ObjToken{type = .EOF},
    }

    iter := common.string_iter_init(input)

    for expected_value in expected {
        actual := string_iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
obj_tokenizer_should_get_vertex_parameter_tokens :: proc(t: ^testing.T) {
    input := "vp 1.0 0.2 3.14\n"

    expected := [?]ObjToken {
        ObjToken{type = .VertexParameter},
        ObjToken{type = .Float, value = 1.0},
        ObjToken{type = .Float, value = 0.2},
        ObjToken{type = .Float, value = 3.14},
        ObjToken{type = .EOF},
    }

    iter := common.string_iter_init(input)

    for expected_value in expected {
        actual := string_iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
obj_tokenizer_should_get_face_tokens :: proc(t: ^testing.T) {
    input := "f 1/2/3\n"

    expected := [?]ObjToken {
        ObjToken{type = .Face},
        ObjToken{type = .Integer, value = 1},
        ObjToken{type = .Slash},
        ObjToken{type = .Integer, value = 2},
        ObjToken{type = .Slash},
        ObjToken{type = .Integer, value = 3},
        ObjToken{type = .EOF},
    }

    iter := common.string_iter_init(input)

    for expected_value in expected {
        actual := string_iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}
