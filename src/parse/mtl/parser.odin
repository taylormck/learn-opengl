package mtl

import "../../types"
import "../common"
import "core:log"

Material :: struct {
    ambient, diffuse, specular, emmisive: types.Vec4,
}

// parse_material :: proc(s: string) -> Material {
//     // TODO: implmenet me
// }

parse_vec4 :: proc(iter: ^MaterialTokenIter) -> (v: types.Vec4, ok: bool) {
    for i in 0 ..< 3 {
        token := material_iter_next(iter)
        assert(token.type == .Float)
        value := token.value.(f32)
        v[i] = value
    }

    next, had_next := material_iter_peek(iter)

    if had_next && next.type == .Float {
        value := next.value.(f32)
        v[3] = value
        material_iter_advance(iter)
    } else {
        v[3] = 1
    }

    return v, true
}

MaterialTokenIter :: struct {
    reader:   common.StringIter,
    previous: MaterialToken,
    peek:     Maybe(MaterialToken),
}

material_iter_init :: proc(s: string) -> MaterialTokenIter {
    iter := MaterialTokenIter {
        reader = common.iter_init(s),
        peek   = nil,
    }

    return iter
}

material_iter_current :: proc(iter: ^MaterialTokenIter) -> MaterialToken {
    return iter.previous
}

material_iter_next :: proc(iter: ^MaterialTokenIter) -> MaterialToken {
    material_iter_advance(iter)
    return iter.previous
}

material_iter_advance :: proc(iter: ^MaterialTokenIter) {
    switch peeked_value in iter.peek {
    case MaterialToken:
        iter.previous = peeked_value
        iter.peek = nil
    case nil:
        iter.previous = iter_get_next_token(&iter.reader)
    }
}

material_iter_is_at_end :: proc(iter: ^MaterialTokenIter) -> bool {
    switch peeked_value in iter.peek {
    case MaterialToken:
        return false
    case nil:
        return common.iter_is_at_end(&iter.reader)
    }
    return true
}

material_iter_peek :: proc(iter: ^MaterialTokenIter) -> (token: MaterialToken, ok: bool) {
    if material_iter_is_at_end(iter) do return

    switch peeked_value in iter.peek {
    case MaterialToken:
        token = peeked_value
        ok = true
    case nil:
        token = iter_get_next_token(&iter.reader)
        ok = true
        iter.peek = token
    }

    return
}
