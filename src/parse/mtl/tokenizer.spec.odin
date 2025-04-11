package mtl

import "../common"
import "core:testing"

@(test)
expect_to_get_eof_token :: proc(t: ^testing.T) {
    input := ""

    iter := common.iter_init(input)

    actual := iter_get_next_token(&iter)

    testing.expect_value(t, actual, MaterialToken{type = .EOF, value = nil})
}

@(test)
expect_to_get_string_tokens :: proc(t: ^testing.T) {
    input := "foo bar\n"

    expected := [?]MaterialToken {
        MaterialToken{type = .String, value = input[:3]},
        MaterialToken{type = .String, value = input[4:7]},
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_int_tokens :: proc(t: ^testing.T) {
    input := "1 2 3\n"

    expected := [?]MaterialToken {
        MaterialToken{type = .Integer, value = 1},
        MaterialToken{type = .Integer, value = 2},
        MaterialToken{type = .Integer, value = 3},
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_float_tokens :: proc(t: ^testing.T) {
    input := "1.0 0.2 3.14\n"

    expected := [?]MaterialToken {
        MaterialToken{type = .Float, value = 1.0},
        MaterialToken{type = .Float, value = 0.2},
        MaterialToken{type = .Float, value = 3.14},
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_material_name_tokens :: proc(t: ^testing.T) {
    input := "newmtl Scene_-_Root"
    expected := [?]MaterialToken {
        MaterialToken{type = .MaterialName},
        MaterialToken{type = .String, value = input[7:]},
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_shininess_tokens :: proc(t: ^testing.T) {
    input := "Ns 225.00000"
    expected := [?]MaterialToken{MaterialToken{type = .Shininess}, MaterialToken{type = .Float, value = 225.0}}

    iter := common.iter_init(input)

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
        "Ks 0.500000 0.500000 0.500000\n" +
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
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_optical_density_tokens :: proc(t: ^testing.T) {
    input := "Ni 1.450000"

    expected := [?]MaterialToken {
        MaterialToken{type = .OpticalDensity},
        MaterialToken{type = .Float, value = 1.45},
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

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
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_transparency_tokens :: proc(t: ^testing.T) {
    input := "Tr 0.1\n" + "d 1.000000"

    expected := [?]MaterialToken {
        MaterialToken{type = .Transparency},
        MaterialToken{type = .Float, value = 0.1},
        MaterialToken{type = .Transparency},
        MaterialToken{type = .Float, value = 1.0},
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_get_transmission_filter_tokens :: proc(t: ^testing.T) {
    input := "Tf 0.1 0.2 0.3\n" + "Tf xyz 1.0 0.5 0.5\n" + "Tf spectral foo.rfl 0.1\n"

    expected := [?]MaterialToken {
        MaterialToken{type = .TransmissionFilter},
        MaterialToken{type = .Float, value = 0.1},
        MaterialToken{type = .Float, value = 0.2},
        MaterialToken{type = .Float, value = 0.3},
        MaterialToken{type = .TransmissionFilter},
        MaterialToken{type = .String, value = "xyz"},
        MaterialToken{type = .Float, value = 1.0},
        MaterialToken{type = .Float, value = 0.5},
        MaterialToken{type = .Float, value = 0.5},
        MaterialToken{type = .TransmissionFilter},
        MaterialToken{type = .String, value = "spectral"},
        MaterialToken{type = .String, value = "foo.rfl"},
        MaterialToken{type = .Float, value = 0.1},
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}


@(test)
expect_to_get_map_tokens :: proc(t: ^testing.T) {
    input := "map_Kd diffuse.jpg\n" + "map_Bump normal.png\n" + "bump normal.png\n" + "map_Ks specular.jpg"

    expected := [?]MaterialToken {
        MaterialToken{type = .DiffuseMap},
        MaterialToken{type = .String, value = "diffuse.jpg"},
        MaterialToken{type = .BumpMap},
        MaterialToken{type = .String, value = "normal.png"},
        MaterialToken{type = .BumpMap},
        MaterialToken{type = .String, value = "normal.png"},
        MaterialToken{type = .SpecularMap},
        MaterialToken{type = .String, value = "specular.jpg"},
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}

@(test)
expect_to_ignore_comments :: proc(t: ^testing.T) {
    input := "# map_Kd diffuse.jpg\n" + "map_Ks specular.jpg"

    expected := [?]MaterialToken {
        MaterialToken{type = .SpecularMap},
        MaterialToken{type = .String, value = "specular.jpg"},
        MaterialToken{type = .EOF},
    }

    iter := common.iter_init(input)

    for expected_value in expected {
        actual := iter_get_next_token(&iter)
        testing.expect_value(t, actual, expected_value)
    }
}
