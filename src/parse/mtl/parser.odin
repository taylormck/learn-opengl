package mtl

import "../../render"
import "../../types"
import "../common"
import "core:log"
import "core:mem"
import "core:strings"

MaterialTokenIter :: common.TokenIter(MaterialToken)

parse_materials :: proc(
    s: string,
    allocator: mem.Allocator = context.allocator,
) -> (
    materials: render.MaterialMap,
    ok: bool,
) {
    context.allocator = allocator
    materials = make(render.MaterialMap)
    current_material: ^render.Material

    iter := common.token_iter_init(MaterialToken, s, string_iter_get_next_token)

    if !common.token_iter_is_at_end(&iter) {
        current := common.token_iter_next(&iter) or_return

        #partial switch current.type {
        case .MaterialName:
            new_name := parse_string(&iter) or_return
            materials[new_name] = render.Material {
                name = new_name,
            }
            current_material = &materials[new_name]
        case:
            log.info("Material data has entries before any material name.")
            delete(materials)
            return materials, false
        }
    }

    for !common.token_iter_is_at_end(&iter) {
        current := common.token_iter_next(&iter) or_return

        #partial switch current.type {
        case .MaterialName:
            new_name := parse_string(&iter) or_return
            materials[new_name] = render.Material {
                name = new_name,
            }
            current_material = &materials[new_name]
        case .Ambient:
            current_material.ambient = parse_vec4(&iter) or_return
        case .Diffuse:
            current_material.diffuse = parse_vec4(&iter) or_return
        case .Specular:
            current_material.specular = parse_vec4(&iter) or_return
        case .Emissive:
            current_material.emissive = parse_vec4(&iter) or_return
        case .Shininess:
            current_material.shininess = parse_float(&iter) or_return

        // TODO: Add support for all of the various options that can apply to textures
        case .DiffuseMap:
            current_material.diffuse_map = parse_string(&iter) or_return
        case .BumpMap:
            current_material.normal_map = parse_string(&iter) or_return
        case .SpecularMap:
            current_material.specular_map = parse_string(&iter) or_return
        // TODO: log errors if we see other tokens
        }
    }

    return materials, true
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
    v = strings.clone(v)

    return v, true
}
