package obj

import "../../render"
import "../../types"
import "../common"
import "../mtl"
import "core:log"
import "core:mem"
import "core:os"

ObjTokenIter :: common.TokenIter(ObjToken)

parse_obj_ref :: proc(
    s: string,
    scene: ^render.Scene,
    load_material_fn: LoadMaterialDataFn = os.read_entire_file_from_filename,
) -> (
    ok: bool,
) {
    iter := common.token_iter_init(ObjToken, s, string_iter_get_next_token)

    for !common.token_iter_is_at_end(&iter) {
        current := common.token_iter_next(&iter) or_return

        #partial switch current.type {
        case .MaterialFile:
            material_file_name := parse_string(&iter) or_return
            parse_material(material_file_name, &scene.materials, load_material_fn)

        case .UseMaterial:
        case .Vertex:
            vertex := parse_vec4(&iter) or_return
            append(&scene.vertices, vertex)

        case .TextureCoordinates:
            coordinates := parse_vec2(&iter) or_return
            append(&scene.texture_coordinates, coordinates)

        case .VertexNormal:
            normal := parse_vec3(&iter) or_return
            append(&scene.normals, normal)

        case .VertexParameter:
        // TODO: implement vertex parameters

        case .ObjectName:
        case .GroupName:
        case .Face:

        // Ignore these for now
        // case .SmoothShading:
        // case .LineElement:
        }
    }

    return true
}

parse_obj_val :: proc(
    s: string,
    load_material_fn: LoadMaterialDataFn = os.read_entire_file_from_filename,
) -> (
    scene: render.Scene,
    ok: bool,
) {
    ok = parse_obj_ref(s, &scene, load_material_fn)
    return
}

parse_obj_alloc :: proc(
    s: string,
    allocator: mem.Allocator,
    load_material_fn: LoadMaterialDataFn = os.read_entire_file_from_filename,
) -> (
    scene: ^render.Scene,
    ok: bool,
) {
    context.allocator = allocator
    scene = new(render.Scene)
    ok = parse_obj_ref(s, scene, load_material_fn)
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

parse_vec2 :: proc(iter: ^ObjTokenIter) -> (v: types.Vec2, ok: bool) {
    for i in 0 ..< 2 {
        token := common.token_iter_next(iter) or_return
        assert(token.type == .Float)
        value := token.value.(f32)
        v[i] = value
    }
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

LoadMaterialDataFn :: #type proc(
    name: string,
    allocator := context.allocator,
    loc := #caller_location,
) -> (
    data: []u8,
    success: bool,
)

parse_material :: proc(
    material_file_name: string,
    materials: ^render.MaterialMap,
    load_material_data: LoadMaterialDataFn,
) -> (
    ok: bool,
) {
    mtl_data, loaded_ok := load_material_data(material_file_name)
    if !loaded_ok {
        log.error("Failed to load material data: {}", material_file_name)
        return false
    }

    new_mats, parse_ok := mtl.parse_materials(string(mtl_data))
    if !parse_ok {
        log.error("Failed to parse material data: {}", material_file_name)
        return false
    }

    for mat_name, mat in new_mats {
        materials[mat_name] = mat
    }

    return true
}
