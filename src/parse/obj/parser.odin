package obj

import "../../render"
import "../../types"
import "../common"
import "core:mem"

ObjTokenIter :: common.TokenIter(ObjToken)

parse_obj_ref :: proc(s: string, scene: ^render.Scene) -> (ok: bool) {
    iter := common.token_iter_init(ObjToken, s, string_iter_get_next_token)

    for !common.token_iter_is_at_end(&iter) {
        current := common.token_iter_next(&iter) or_return

        #partial switch current.type {
        case .MaterialFile:
            material_file_name := parse_string(&iter) or_return
            append(&scene.materials, material_file_name)

        case .UseMaterial:
        case .Vertex:
        case .TextureCoordinates:
        case .VertexNormal:
        case .VertexParameter:
        case .Face:
        case .GroupName:

        // Ignore these for now
        // case .SmoothShading:
        // case .LineElement:
        }
    }

    return true
}

parse_obj_val :: proc(s: string) -> (material: render.Scene, ok: bool) {
    ok = parse_obj_ref(s, &material)
    return
}

parse_obj_alloc :: proc(s: string, allocator: mem.Allocator) -> (material: ^render.Scene, ok: bool) {
    context.allocator = allocator
    material = new(render.Scene)
    ok = parse_obj_ref(s, material)
    return
}

parse_obj :: proc {
    parse_obj_ref,
    parse_obj_val,
    parse_obj_alloc,
}

parse_float :: proc(iter: ^ObjTokenIter) -> (v: f32, ok: bool) {
    next_token := common.token_iter_peek(iter) or_return
    if next_token.type != .Float do return
    v = next_token.value.(f32)

    return v, true
}

parse_vec3 :: proc(iter: ^ObjTokenIter) -> (v: types.Vec3, ok: bool) {
    for i in 0 ..< 3 {
        token := common.token_iter_next(iter) or_return
        assert(token.type == .Float)
        value := token.value.(f32)
        v[i] = value
    }
    return v, true
}

parse_vec4 :: proc(iter: ^ObjTokenIter) -> (v: types.Vec4, ok: bool) {
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

parse_int :: proc(iter: ^ObjTokenIter) -> (v: i32, ok: bool) {
    next_token := common.token_iter_peek(iter) or_return
    if next_token.type != .Integer do return
    v = next_token.value.(i32)

    return v, true
}

parse_string :: proc(iter: ^ObjTokenIter) -> (v: string, ok: bool) {
    next_token := common.token_iter_peek(iter) or_return
    if next_token.type != .String do return
    v = next_token.value.(string)

    return v, true
}
