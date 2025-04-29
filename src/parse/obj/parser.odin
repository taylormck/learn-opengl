package obj

import "../../render"
import "../../types"
import "../common"
import "../mtl"
import "core:log"
import "core:mem"
import "core:os"
import "core:strings"

ObjTokenIter :: common.TokenIter(ObjToken)
VertexMap :: map[render.MeshVertex]int

parse_obj_ref :: proc(
    s: string,
    scene: ^render.Scene,
    load_material_fn: LoadMaterialDataFn = os.read_entire_file_from_filename,
) -> (
    ok: bool,
) {
    iter := common.token_iter_init(ObjToken, s, string_iter_get_next_token)

    if scene.meshes != nil {
        delete(scene.meshes)
    }

    scene.meshes = make(render.MeshMap)
    scene.meshes[""] = render.Mesh{}
    current_mesh := &scene.meshes[""]
    vertex_map := make(VertexMap)
    defer delete(vertex_map)

    current_material := ""

    for !common.token_iter_is_at_end(&iter) {
        current := common.token_iter_next(&iter) or_return

        #partial switch current.type {
        case .MaterialFile:
            material_file_name := parse_string(&iter) or_return
            parse_material(material_file_name, &scene.materials, load_material_fn)

        case .UseMaterial:
            current_material = parse_string(&iter) or_return

            delete(current_mesh.material)
            current_mesh.material = strings.clone(current_material)

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
            new_mesh_name := parse_string(&iter) or_return
            if !(new_mesh_name in scene.meshes) do scene.meshes[new_mesh_name] = render.Mesh{}
            current_mesh = &scene.meshes[new_mesh_name]

            delete(current_mesh.material)
            current_mesh.material = strings.clone(current_material)

            delete(vertex_map)
            vertex_map := make(VertexMap)

        case .Face:
            new_indices: types.Vec3u
            for i in 0 ..< 3 {
                new_vertex := parse_vertex(&iter, scene) or_return
                index, found := vertex_map[new_vertex]

                if !found {
                    append(&current_mesh.vertices, new_vertex)
                    index = len(current_mesh.vertices)
                    vertex_map[new_vertex] = index
                }

                new_indices[i] = u32(index)
            }

            append(&current_mesh.indices, new_indices)

        // Ignore these for now
        // case .GroupName:
        // case .SmoothShading:
        // case .LineElement:
        }
    }

    // Remove any meshes that didn't have any vertices
    for key, &mesh in scene.meshes {
        if len(mesh.vertices) != 0 do continue
        if len(mesh.indices) != 0 do continue

        render.mesh_free(&mesh)
        delete_key(&scene.meshes, key)
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
    common.token_iter_advance(iter)

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
    common.token_iter_advance(iter)

    v = next_token.value.(i32)

    return v, true
}

parse_string :: proc(iter: ^ObjTokenIter) -> (v: string, ok: bool) {
    next_token := common.token_iter_peek(iter) or_return

    if next_token.type != .String do return
    common.token_iter_advance(iter)

    v = next_token.value.(string)

    return v, true
}

parse_vertex :: proc(iter: ^ObjTokenIter, scene: ^render.Scene) -> (v: render.MeshVertex, ok: bool) {
    // Start by getting the position
    next_token := common.token_iter_next(iter) or_return
    if next_token.type != .Integer do return
    index := next_token.value.(i32)
    assert(int(index) <= len(scene.vertices))

    // We only need x, y, and z.
    v.position = scene.vertices[index - 1].xyz

    next_token = common.token_iter_next(iter) or_return
    if next_token.type != .Slash do return

    // The vertex coordinates are optional, and default to {0, 0}
    next_token = common.token_iter_next(iter) or_return
    if next_token.type == .Integer {
        index = next_token.value.(i32)
        assert(int(index) <= len(scene.texture_coordinates))
        v.texture_coordinates = scene.texture_coordinates[index - 1]

        next_token = common.token_iter_next(iter) or_return
    }

    if next_token.type != .Slash do return

    // Finally, get the normal
    next_token = common.token_iter_next(iter) or_return
    if next_token.type != .Integer do return
    index = next_token.value.(i32)
    assert(int(index) <= len(scene.normals))
    v.normal = scene.normals[index - 1]

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
    defer delete(mtl_data)

    new_mats, parse_ok := mtl.parse_materials(string(mtl_data))
    if !parse_ok {
        log.error("Failed to parse material data: {}", material_file_name)
        return false
    }
    defer delete(new_mats)

    for mat_name, mat in new_mats {
        materials[mat_name] = mat
    }

    return true
}
