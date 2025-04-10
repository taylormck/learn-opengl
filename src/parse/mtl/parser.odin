package mtl

import "../../render"
import "core:log"
import "core:strconv"

Material :: render.Material

parse_material :: proc(input: string, material: ^Material) {

}

MaterialTokenType :: enum {
    MaterialName,
    Shininess,
    Ambient,
    Diffuse,
    Specular,
    Emissive,
    OpticalDensity,
    IlluminationModel,
    DiffuseMap,
    BumpMap,
    SpecularMap,
    Integer,
    Float,
    String,
    EOF,
}

MaterialTokenValue :: union {
    i32,
    f32,
    string,
}

MaterialToken :: struct {
    type:  MaterialTokenType,
    value: Maybe(MaterialTokenValue),
}

MaterialParserIter :: struct {
    index, line, column: int,
    data:                string,
}

iter_get_next_token :: proc(iter: ^MaterialParserIter) -> MaterialToken {
    start_index := iter.index
    end_index := iter.index

    find_next_token_start: for iter.index < len(iter.data) {
        current := iter_current(iter)

        switch current {
        case 'A' ..= 'Z', 'a' ..= 'z':
            start_index = iter.index

            for is_valid_identifier_char(current) {
                iter_advance(iter)
                if iter.index >= len(iter.data) do break

                current = iter_current(iter)
            }

            end_index = iter.index
            break find_next_token_start
        case '0' ..= '9':
            start_index = iter.index

            for is_valid_numerical_char(current) {
                iter_advance(iter)
                if iter.index >= len(iter.data) do break

                current = iter_current(iter)
            }

            end_index = iter.index
            break find_next_token_start
        }


        iter_advance(iter)
    }

    value := iter.data[start_index:end_index]
    log.infof("value: {}", value)

    switch value {
    case "newmtl":
        return MaterialToken{type = .MaterialName}
    case "Ns":
        return MaterialToken{type = .Shininess}
    case "Ka":
        return MaterialToken{type = .Ambient}
    case "Kd":
        return MaterialToken{type = .Diffuse}
    case "Ks":
        return MaterialToken{type = .Specular}
    case "Ke":
        return MaterialToken{type = .Emissive}
    case "Ni":
        return MaterialToken{type = .OpticalDensity}
    case "illum":
        return MaterialToken{type = .IlluminationModel}
    case "map_Kd":
        return MaterialToken{type = .DiffuseMap}
    case "map_Bump":
        return MaterialToken{type = .BumpMap}
    case "map_Ks":
        return MaterialToken{type = .SpecularMap}
    case:
        switch {
        case len(value) == 0:
            return MaterialToken{type = .EOF}
        case is_float(value):
            val, ok := strconv.parse_f32(value)
            if !ok {
                log.errorf("Failed to parse float: {}", value)
                return iter_get_next_token(iter)
            }
            return MaterialToken{type = .Float, value = val}
        case is_integer(value):
            val, ok := strconv.parse_int(value)
            if !ok {
                log.errorf("Failed to parse integer: {}", value)
                return iter_get_next_token(iter)
            }
            return MaterialToken{type = .Integer, value = i32(val)}
        case:
            return MaterialToken{type = .String, value = value}
        }
    }
}

iter_current :: proc(iter: ^MaterialParserIter) -> u8 {
    return iter.data[iter.index]
}

iter_advance :: proc(iter: ^MaterialParserIter) {
    iter.index += 1
}

is_valid_identifier_char :: proc(c: u8) -> bool {
    switch c {
    case 'a' ..= 'z', 'A' ..= 'Z', '0' ..= '9', '-', '_', '.':
        return true

    case:
        return false
    }
}

is_valid_numerical_char :: proc(c: u8) -> bool {
    switch c {
    case '0' ..= '9', '.':
        return true
    case:
        return false
    }
}

is_digit :: proc(c: rune) -> bool {
    return c >= '0' && c <= '9'
}

is_float :: proc(s: string) -> bool {
    found_period := false
    for c in s {
        if is_digit(c) do continue
        if c != '.' do return false
        if found_period do return false
        found_period = true
    }

    return found_period
}

is_integer :: proc(s: string) -> bool {
    for c in s {
        if !is_digit(c) do return false
    }

    return true
}
