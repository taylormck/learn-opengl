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

parse_float :: proc(iter: ^MaterialTokenIter) -> (v: f32, ok: bool) {
    next_token := material_iter_peek(iter) or_return
    if next_token.type != .Float do return
    v = next_token.value.(f32)

    return v, true
}

parse_vec4 :: proc(iter: ^MaterialTokenIter) -> (v: types.Vec4, ok: bool) {
    for i in 0 ..< 3 {
        token := material_iter_next(iter) or_return
        assert(token.type == .Float)
        value := token.value.(f32)
        v[i] = value
    }

    next, had_next := material_iter_peek(iter)

    if had_next && next.type == .Float {
        value := next.value.(f32)
        v[3] = value
        material_iter_advance(iter) or_return
    } else {
        v[3] = 1
    }

    return v, true
}

parse_int :: proc(iter: ^MaterialTokenIter) -> (v: i32, ok: bool) {
    next_token := material_iter_peek(iter) or_return
    if next_token.type != .Integer do return
    v = next_token.value.(i32)

    return v, true
}

parse_string :: proc(iter: ^MaterialTokenIter) -> (v: string, ok: bool) {
    next_token := material_iter_peek(iter) or_return
    if next_token.type != .String do return
    v = next_token.value.(string)

    return v, true
}
