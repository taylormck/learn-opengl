package obj

import "../../render"
import "../../types"
import "../common"
import "core:log"
import "core:strings"
import "core:testing"


@(test)
parse_float_should_parse_float :: proc(t: ^testing.T) {
    input := "225.500000"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected: f32 = 225.5
    actual, ok := parse_float(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_vec2_should_parse_2_floats :: proc(t: ^testing.T) {
    input := "0.1 0.25"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected := types.Vec2{0.1, 0.25}
    actual, ok := parse_vec2(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_vec3_should_parse_3_floats :: proc(t: ^testing.T) {
    input := "0.1 0.25 0.5"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected := types.Vec3{0.1, 0.25, 0.5}
    actual, ok := parse_vec3(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_vec4_should_parse_4_floats :: proc(t: ^testing.T) {
    input := "0.1 0.25 0.5 0.75"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected := types.Vec4{0.1, 0.25, 0.5, 0.75}
    actual, ok := parse_vec4(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}


@(test)
parse_int_should_parse_int :: proc(t: ^testing.T) {
    input := "2"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected: i32 = 2
    actual, ok := parse_int(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_string_should_parse_string :: proc(t: ^testing.T) {
    input := "test"

    iter := common.token_iter_init(ObjToken, input, string_iter_get_next_token)

    expected := "test"
    actual, ok := parse_string(&iter)

    testing.expect(t, ok)
    testing.expect_value(t, actual, expected)
}

@(test)
parse_obj_should_parse_a_single_face :: proc(t: ^testing.T) {
    input :=
        ("v -0.5 -0.5 0.5\n" +
            "v 0.5 -0.5 1.0\n" +
            "v 0.0 0.5 -0.5\n" +
            "vt 0.25 0.25\n" +
            "vt 0.75 0.75\n" +
            "vt 0.5 0.75\n" +
            "vn 0.0001 0.9989 0.0473\n" +
            "f 1/1/1 2/2/1 3/3/1\n")

    expected_vertices := [?]render.MeshVertex {
        render.MeshVertex {
            position = {-0.5, -0.5, 0.5},
            texture_coordinates = {0.25, 0.25},
            normal = {0.0001, 0.9989, 0.0473},
        },
        render.MeshVertex {
            position = {0.5, -0.5, 1.0},
            texture_coordinates = {0.75, 0.75},
            normal = {0.0001, 0.9989, 0.0473},
        },
        render.MeshVertex {
            position = {0.0, 0.5, -0.5},
            texture_coordinates = {0.5, 0.75},
            normal = {0.0001, 0.9989, 0.0473},
        },
    }

    expected_indices := [?]types.Vec3u{{0, 1, 2}}

    expected := render.Mesh{}
    defer render.mesh_free(&expected)

    append(&expected.vertices, ..expected_vertices[:])
    append(&expected.indices, ..expected_indices[:])

    actual_scene, ok := parse_obj(input, "")
    defer render.scene_destroy(&actual_scene)

    testing.expect(t, ok)

    actual_mesh := actual_scene.meshes[""]
    expect_mesh_match(t, &actual_mesh, &expected)
}

@(test)
parse_obj_should_parse_multiple_faces_with_shared_vertices :: proc(t: ^testing.T) {
    input :=
        ("v -1.0 -1.0 0.0\n" +
            "v 1.0 -1.0 0.0\n" +
            "v -1.0 1.0 0.0\n" +
            "v 1.0 1.0 0.0\n" +
            "vt 0.0 0.0\n" +
            "vt 1.0 0.0\n" +
            "vt 0.0 1.0\n" +
            "vt 1.0 1.0\n" +
            "vn 0.0001 0.9989 0.0473\n" +
            "f 1/1/1 2/2/1 3/3/1\n" +
            "f 2/2/1 4/4/1 3/3/1\n")

    expected_vertices := [?]render.MeshVertex {
        render.MeshVertex{position = {-1, -1, 0}, texture_coordinates = {0, 0}, normal = {0.0001, 0.9989, 0.0473}},
        render.MeshVertex{position = {1, -1, 0}, texture_coordinates = {1, 0}, normal = {0.0001, 0.9989, 0.0473}},
        render.MeshVertex{position = {-1, 1, 0}, texture_coordinates = {0, 1}, normal = {0.0001, 0.9989, 0.0473}},
        render.MeshVertex{position = {1, 1, 0}, texture_coordinates = {1, 1}, normal = {0.0001, 0.9989, 0.0473}},
    }
    expected_indices := [?]types.Vec3u{{0, 1, 2}, {1, 3, 2}}

    expected := render.Mesh{}
    defer render.mesh_free(&expected)

    append(&expected.vertices, ..expected_vertices[:])
    append(&expected.indices, ..expected_indices[:])

    actual_scene, ok := parse_obj(input, "")
    defer render.scene_destroy(&actual_scene)

    testing.expect(t, ok)

    actual_mesh := actual_scene.meshes[""]
    expect_mesh_match(t, &actual_mesh, &expected)
}

@(test)
parse_obj_should_parse_object_with_material_with_usemtl_after_o :: proc(t: ^testing.T) {
    input :=
        ("mtllib mymat.mtl\n" +
            "o myobj\n" +
            "usemtl mymat\n" +
            "v -1.0 -1.0 0.0\n" +
            "v 1.0 -1.0 0.0\n" +
            "v -1.0 1.0 0.0\n" +
            "v 1.0 1.0 0.0\n" +
            "vt 0.0 0.0\n" +
            "vt 1.0 0.0\n" +
            "vt 0.0 1.0\n" +
            "vt 1.0 1.0\n" +
            "vn 0.0001 0.9989 0.0473\n" +
            "f 1/1/1 2/2/1 3/3/1\n" +
            "f 2/2/1 4/4/1 3/3/1\n")

    expected_vertices := [?]render.MeshVertex {
        render.MeshVertex{position = {-1, -1, 0}, texture_coordinates = {0, 0}, normal = {0.0001, 0.9989, 0.0473}},
        render.MeshVertex{position = {1, -1, 0}, texture_coordinates = {1, 0}, normal = {0.0001, 0.9989, 0.0473}},
        render.MeshVertex{position = {-1, 1, 0}, texture_coordinates = {0, 1}, normal = {0.0001, 0.9989, 0.0473}},
        render.MeshVertex{position = {1, 1, 0}, texture_coordinates = {1, 1}, normal = {0.0001, 0.9989, 0.0473}},
    }

    expected_indices := [?]types.Vec3u{{0, 1, 2}, {1, 3, 2}}

    expected_mesh := render.Mesh {
        material = strings.clone("mymat"),
    }

    append(&expected_mesh.vertices, ..expected_vertices[:])
    append(&expected_mesh.indices, ..expected_indices[:])

    meshes: render.MeshMap
    meshes["myobj"] = expected_mesh

    materials: render.MaterialMap

    materials["mymat"] = render.Material {
        name         = strings.clone("mymat"),
        ambient      = {0.1, 0.25, 0.5, 1},
        diffuse      = {0.1, 0.25, 0.5, 1},
        specular     = {0.1, 0.25, 0.5, 1},
        emissive     = {0.1, 0.25, 0.5, 1},
        shininess    = 225,
        diffuse_map  = strings.clone("diffuse.jpg"),
        normal_map   = strings.clone("normal.png"),
        specular_map = strings.clone("specular.jpg"),
    }

    expected_scene := render.Scene {
        materials = materials,
        meshes    = meshes,
    }
    // Note that most of the things allocated in this test will be freed by scene_destroy here.
    defer render.scene_destroy(&expected_scene)

    actual_scene, ok := parse_obj(input, "", load_mock_material_data)
    defer render.scene_destroy(&actual_scene)

    testing.expect(t, ok)
    expect_scene_match(t, &actual_scene, &expected_scene)
}

@(test)
parse_obj_should_parse_object_with_material_with_usemtl_before_o :: proc(t: ^testing.T) {
    input :=
        ("mtllib mymat.mtl\n" +
            "usemtl mymat\n" +
            "o myobj\n" +
            "v -1.0 -1.0 0.0\n" +
            "v 1.0 -1.0 0.0\n" +
            "v -1.0 1.0 0.0\n" +
            "v 1.0 1.0 0.0\n" +
            "vt 0.0 0.0\n" +
            "vt 1.0 0.0\n" +
            "vt 0.0 1.0\n" +
            "vt 1.0 1.0\n" +
            "vn 0.0001 0.9989 0.0473\n" +
            "f 1/1/1 2/2/1 3/3/1\n" +
            "f 2/2/1 4/4/1 3/3/1\n")

    expected_vertices := [?]render.MeshVertex {
        render.MeshVertex{position = {-1, -1, 0}, texture_coordinates = {0, 0}, normal = {0.0001, 0.9989, 0.0473}},
        render.MeshVertex{position = {1, -1, 0}, texture_coordinates = {1, 0}, normal = {0.0001, 0.9989, 0.0473}},
        render.MeshVertex{position = {-1, 1, 0}, texture_coordinates = {0, 1}, normal = {0.0001, 0.9989, 0.0473}},
        render.MeshVertex{position = {1, 1, 0}, texture_coordinates = {1, 1}, normal = {0.0001, 0.9989, 0.0473}},
    }

    expected_indices := [?]types.Vec3u{{0, 1, 2}, {1, 3, 2}}

    expected_mesh := render.Mesh {
        material = strings.clone("mymat"),
    }

    append(&expected_mesh.vertices, ..expected_vertices[:])
    append(&expected_mesh.indices, ..expected_indices[:])

    meshes: render.MeshMap
    meshes["myobj"] = expected_mesh

    materials: render.MaterialMap

    materials["mymat"] = render.Material {
        name         = strings.clone("mymat"),
        ambient      = {0.1, 0.25, 0.5, 1},
        diffuse      = {0.1, 0.25, 0.5, 1},
        specular     = {0.1, 0.25, 0.5, 1},
        emissive     = {0.1, 0.25, 0.5, 1},
        shininess    = 225,
        diffuse_map  = strings.clone("diffuse.jpg"),
        normal_map   = strings.clone("normal.png"),
        specular_map = strings.clone("specular.jpg"),
    }

    expected_scene := render.Scene {
        materials = materials,
        meshes    = meshes,
    }
    // Note that most of the things allocated in this test will be freed by scene_destroy here.
    defer render.scene_destroy(&expected_scene)

    actual_scene, ok := parse_obj(input, "", load_mock_material_data)
    defer render.scene_destroy(&actual_scene)

    testing.expect(t, ok)
    expect_scene_match(t, &actual_scene, &expected_scene)
}


expect_scene_match :: proc(t: ^testing.T, actual, expected: ^render.Scene) {
    testing.expect_value(t, len(actual.materials), len(expected.materials))
    for key, expected_value in expected.materials {
        testing.expect_value(t, actual.materials[key], expected_value)
    }

    testing.expect_value(t, len(actual.meshes), len(expected.meshes))
    for key, &expected_mesh in expected.meshes {
        actual_mesh := &actual.meshes[key]

        expect_mesh_match(t, actual_mesh, &expected_mesh)
    }
}

expect_mesh_match :: proc(t: ^testing.T, actual, expected: ^render.Mesh) {
    testing.expect_value(t, actual.material, expected.material)

    testing.expect_value(t, len(actual.vertices), len(expected.vertices))
    for i in 0 ..< len(expected.vertices) {
        testing.expect_value(t, actual.vertices[i], expected.vertices[i])
    }

    testing.expect_value(t, len(actual.indices), len(expected.indices))
    for i in 0 ..< len(expected.indices) {
        testing.expect_value(t, actual.indices[i], expected.indices[i])
    }
}

load_mock_material_data :: proc(
    name: string,
    allocator := context.allocator,
    loc := #caller_location,
) -> (
    data: []u8,
    success: bool,
) {
    data_string := strings.clone(
        "newmtl mymat\n" +
        "Ns 225.000000\n" +
        "Ka 0.100000 0.250000 0.500000\n" +
        "Kd 0.100000 0.250000 0.500000\n" +
        "Ks 0.100000 0.250000 0.500000\n" +
        "Ke 0.1 0.25 0.5\n" +
        "Ni 1.450000\n" +
        "d 1.000000\n" +
        "illum 2\n" +
        "map_Kd diffuse.jpg\n" +
        "map_Bump normal.png\n" +
        "map_Ks specular.jpg\n",
    )

    data = transmute([]u8)data_string

    return data, true
}
