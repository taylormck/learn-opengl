package mtl

import "../../render"
import "../../types"
import "../common"
import "core:mem"

MaterialTokenIter :: common.TokenIter(MaterialToken)

parse_material_ref :: proc(s: string, material: ^render.Material) -> (ok: bool) {
    iter := common.token_iter_init(MaterialToken, s, string_iter_get_next_token)

    for !common.token_iter_is_at_end(&iter) {
        current := common.token_iter_next(&iter) or_return

        #partial switch current.type {
        case .MaterialName:
            material.name = parse_string(&iter) or_return
        case .Ambient:
            material.ambient = parse_vec4(&iter) or_return
        case .Diffuse:
            material.diffuse = parse_vec4(&iter) or_return
        case .Specular:
            material.specular = parse_vec4(&iter) or_return
        case .Emissive:
            material.emmisive = parse_vec4(&iter) or_return
        case .Shininess:
            material.shininess = parse_float(&iter) or_return

        // TODO: Add support for all of the various options that can apply to textures
        case .DiffuseMap:
            material.diffuse_map = parse_string(&iter) or_return
        case .BumpMap:
            material.normal_map = parse_string(&iter) or_return
        case .SpecularMap:
            material.specular_map = parse_string(&iter) or_return
        // TODO: log errors if we see other tokens
        }
    }

    return true
}

parse_material_val :: proc(s: string) -> (material: render.Material, ok: bool) {
    ok = parse_material_ref(s, &material)
    return
}

parse_material_alloc :: proc(s: string, allocator: mem.Allocator) -> (material: ^render.Material, ok: bool) {
    context.allocator = allocator
    material = new(render.Material)
    ok = parse_material_ref(s, material)
    return
}

parse_material :: proc {
    parse_material_ref,
    parse_material_val,
    parse_material_alloc,
}

parse_float :: proc(iter: ^MaterialTokenIter) -> (v: f32, ok: bool) {
    next_token := common.token_iter_peek(iter) or_return
    if next_token.type != .Float do return
    v = next_token.value.(f32)

    return v, true
}

parse_vec4 :: proc(iter: ^MaterialTokenIter) -> (v: types.Vec4, ok: bool) {
    for i in 0 ..< 3 {
        token := common.token_iter_next(iter) or_return
        assert(token.type == .Float)
        value := token.value.(f32)
        v[i] = value
    }

    next, had_next := common.token_iter_peek(iter)

    if had_next && next.type == .Float {
        value := next.value.(f32)
        v[3] = value
        common.token_iter_advance(iter) or_return
    } else {
        v[3] = 1
    }

    return v, true
}

parse_int :: proc(iter: ^MaterialTokenIter) -> (v: i32, ok: bool) {
    next_token := common.token_iter_peek(iter) or_return
    if next_token.type != .Integer do return
    v = next_token.value.(i32)

    return v, true
}

parse_string :: proc(iter: ^MaterialTokenIter) -> (v: string, ok: bool) {
    next_token := common.token_iter_peek(iter) or_return
    if next_token.type != .String do return
    v = next_token.value.(string)

    return v, true
}
