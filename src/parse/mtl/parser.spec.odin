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
    input :=
        "Ka 1.000000 1.000000 1.000000\n" +
        "Kd 0.800000 0.800000 0.800000\n" +
        "Ks 0.500000 0.500000 0.500000" +
        "Ke 0.000000 0.000000 0.000000"

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
        MaterialToken{type = .Emissive},
        MaterialToken{type = .Float, value = 0.0},
        MaterialToken{type = .Float, value = 0.0},
        MaterialToken{type = .Float, value = 0.0},
    }

    iter := MaterialParserIter {
        data = input,
    }

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_optical_density_tokens :: proc(t: ^testing.T) {
    input := "Ni 1.450000"

    expected := [?]MaterialToken{MaterialToken{type = .OpticalDensity}, MaterialToken{type = .Float, value = 1.45}}

    iter := MaterialParserIter {
        data = input,
    }

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_illumination_model_tokens :: proc(t: ^testing.T) {
    input := "illum 2"

    expected := [?]MaterialToken {
        MaterialToken{type = .IlluminationModel},
        MaterialToken{type = .Integer, value = i32(2)},
    }

    iter := MaterialParserIter {
        data = input,
    }

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_map_tokens :: proc(t: ^testing.T) {
    input := "map_Kd diffuse.jpg\n" + "map_Bump normal.png\n" + "map_Ks specular.jpg"

    expected := [?]MaterialToken {
        MaterialToken{type = .DiffuseMap},
        MaterialToken{type = .String, value = "diffuse.jpg"},
        MaterialToken{type = .BumpMap},
        MaterialToken{type = .String, value = "normal.png"},
        MaterialToken{type = .SpecularMap},
        MaterialToken{type = .String, value = "specular.jpg"},
    }

    iter := MaterialParserIter {
        data = input,
    }

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}
