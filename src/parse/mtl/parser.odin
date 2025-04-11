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
    ok = true

    return
}

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
