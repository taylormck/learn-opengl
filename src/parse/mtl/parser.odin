package mtl

import "../../render"
import "core:log"

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

MaterialToken :: struct {
    type:  MaterialTokenType,
    value: Maybe(string),
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
        }

        iter_advance(iter)
    }

    value := iter.data[start_index:end_index]

    switch value {
    case "newmtl":
        return MaterialToken{type = .MaterialName}
    case:
        if len(value) == 0 do return MaterialToken{type = .EOF}
        else do return MaterialToken{type = .String, value = value}
    }
}

iter_current :: proc(iter: ^MaterialParserIter) -> u8 {
    return iter.data[iter.index]
}

iter_advance :: proc(iter: ^MaterialParserIter) {
    iter.index += 1
}

is_valid_identifier_char :: proc(c: u8) -> bool {
    if c >= 'a' && c <= 'z' do return true
    if c >= 'A' && c <= 'Z' do return true
    if c >= '0' && c <= '9' do return true
    if c == '-' do return true
    if c == '_' do return true

    return false
}
