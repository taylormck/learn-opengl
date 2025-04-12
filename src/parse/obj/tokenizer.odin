package obj

import "../common"
import "core:log"
import "core:strconv"

ObjTokenType :: enum {
    ObjectName,
    GroupName,
    Material,
    UseMaterial,
    Vertex,
    TextureCoordinates,
    VertexNormal,
    VertexParameter,
    LineElement,
    Face,
    Slash,
    SmoothShading,
    Integer,
    Float,
    String,
    EOF,
}

ObjTokenValue :: union {
    i32,
    f32,
    string,
}

ObjToken :: struct {
    type:  ObjTokenType,
    value: ObjTokenValue,
}

string_iter_get_next_token :: proc(iter: ^common.StringIter) -> ObjToken {
    start_index := common.string_iter_get_current_index(iter)

    find_next_token_start: for !common.string_iter_is_at_end(iter) {
        start_index = common.string_iter_get_current_index(iter)
        current := common.string_iter_next(iter)

        switch current {
        case '#':
            for current != '\n' {
                current = common.string_iter_next(iter)
                if common.string_iter_is_at_end(iter) do break
            }

        case '/':
            break find_next_token_start

        case 'A' ..= 'Z', 'a' ..= 'z':
            for !common.string_iter_is_at_end(iter) {
                next := common.string_iter_peek(iter)
                if !common.is_valid_string_char(next) do break
                common.string_iter_advance(iter)
            }

            break find_next_token_start

        case '0' ..= '9', '-':
            for !common.string_iter_is_at_end(iter) {
                next := common.string_iter_peek(iter)
                if !common.is_valid_numerical_char(next) do break
                common.string_iter_advance(iter)
            }

            break find_next_token_start
        }

        // NOTE: there has to be a better way to do this
        start_index += 1
    }

    end_index := common.string_iter_get_current_index(iter)
    value := common.string_iter_slice(iter, start_index, end_index)

    switch value {
    case "matllib":
        return ObjToken{type = .Material}
    case "usemtl":
        return ObjToken{type = .UseMaterial}
    case "v":
        return ObjToken{type = .Vertex}
    case "vt":
        return ObjToken{type = .TextureCoordinates}
    case "vn":
        return ObjToken{type = .VertexNormal}
    case "vp":
        return ObjToken{type = .VertexParameter}
    case "f":
        return ObjToken{type = .Face}
    case "g":
        return ObjToken{type = .GroupName}
    case "s":
        return ObjToken{type = .SmoothShading}
    case "l":
        return ObjToken{type = .LineElement}
    case "/":
        return ObjToken{type = .Slash}

    case:
        switch {
        case len(value) == 0:
            return ObjToken{type = .EOF}
        case common.is_float(value):
            val, ok := strconv.parse_f32(value)
            if !ok {
                log.errorf("Failed to parse float: {}", value)
                return string_iter_get_next_token(iter)
            }
            return ObjToken{type = .Float, value = val}
        case common.is_integer(value):
            val, ok := strconv.parse_int(value)
            if !ok {
                log.errorf("Failed to parse integer: {}", value)
                return string_iter_get_next_token(iter)
            }
            return ObjToken{type = .Integer, value = i32(val)}
        case:
            return ObjToken{type = .String, value = value}
        }
    }
}
