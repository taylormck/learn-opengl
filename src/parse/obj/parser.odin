package obj

import "../../render"
import "../../types"
import "../common"
import "../mtl"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:strings"

ObjTokenIter :: common.TokenIter(ObjToken)
VertexMap :: map[render.MeshVertex]uint

load_scene_from_file_obj :: proc(dir_path, file_name: string) -> (scene: render.Scene, ok: bool) {
	log.infof("Loading scene from file: {}/{}", dir_path, file_name)

	path := fmt.tprintf("{}/{}", dir_path, file_name)
	scene_file_data := os.read_entire_file(path) or_return
	defer delete(scene_file_data)

	scene = parse_obj(string(scene_file_data), dir_path) or_return

	for mesh_name, &mesh in scene.meshes {
		material, has_material := scene.materials[mesh.material_name]

		if !has_material {
			log.errorf("material not found: {}", mesh.material_name)
			continue
		}

		mesh.material = material

		if len(material.diffuse_map) > 0 {
			texture, has_texture := scene.textures[material.diffuse_map]

			if !has_texture {
				full_texture_path := fmt.caprintf("{}/{}", dir_path, material.diffuse_map)
				defer delete(full_texture_path)

				texture = render.prepare_texture(full_texture_path, .Diffuse)
				scene.textures[material.diffuse_map] = texture
			}

			append(&mesh.textures, texture)
		}

		if len(material.specular_map) > 0 {
			texture, has_texture := scene.textures[material.specular_map]

			if !has_texture {
				full_texture_path := fmt.caprintf("{}/{}", dir_path, material.specular_map)
				defer delete(full_texture_path)

				texture = render.prepare_texture(full_texture_path, .Specular)
				scene.textures[material.specular_map] = texture
			}

			append(&mesh.textures, texture)
		}

		if len(material.normal_map) > 0 {
			texture, has_texture := scene.textures[material.normal_map]

			if !has_texture {
				full_texture_path := fmt.caprintf("{}/{}", dir_path, material.normal_map)
				defer delete(full_texture_path)

				texture = render.prepare_texture(full_texture_path, .Normal)
				scene.textures[material.normal_map] = texture
			}

			append(&mesh.textures, texture)
		}
	}

	return scene, true
}

parse_obj_ref :: proc(
	s, dir: string,
	scene: ^render.Scene,
	load_material_fn: LoadMaterialDataFn = os.read_entire_file_from_filename,
) -> (
	ok: bool,
) {
	builder: SceneBuilder
	defer scene_builder_destroy(&builder)

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
			material_path := fmt.tprintf("{}/{}", dir, material_file_name)

			parse_material(material_path, scene, load_material_fn)

		case .UseMaterial:
			current_material = parse_string(&iter) or_return

			delete(current_mesh.material_name)
			current_mesh.material_name = strings.clone(current_material)

		case .Vertex:
			vertex := parse_vec4(&iter) or_return
			append(&builder.vertices, vertex)

		case .TextureCoordinates:
			coordinates := parse_vec2(&iter) or_return
			append(&builder.texture_coordinates, coordinates)

		case .VertexNormal:
			normal := parse_vec3(&iter) or_return
			append(&builder.normals, normal)

		case .VertexParameter:
		// TODO: implement vertex parameters

		case .ObjectName:
			new_mesh_name := parse_string(&iter) or_return
			if !(new_mesh_name in scene.meshes) do scene.meshes[new_mesh_name] = render.Mesh{}
			current_mesh = &scene.meshes[new_mesh_name]

			delete(current_mesh.material_name)
			current_mesh.material_name = strings.clone(current_material)

			clear(&vertex_map)

		case .Face:
			new_indices: types.Vec3u
			for i in 0 ..< 3 {
				new_vertex := parse_vertex(&iter, &builder) or_return
				index, found := vertex_map[new_vertex]

				if !found {
					append(&current_mesh.vertices, new_vertex)
					index = len(current_mesh.vertices) - 1
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
	s, dir: string,
	load_material_fn: LoadMaterialDataFn = os.read_entire_file_from_filename,
) -> (
	scene: render.Scene,
	ok: bool,
) {
	ok = parse_obj_ref(s, dir, &scene, load_material_fn)
	return
}

parse_obj_alloc :: proc(
	s, dir: string,
	allocator: mem.Allocator,
	load_material_fn: LoadMaterialDataFn = os.read_entire_file_from_filename,
) -> (
	scene: ^render.Scene,
	ok: bool,
) {
	context.allocator = allocator
	scene = new(render.Scene)
	ok = parse_obj_ref(s, dir, scene, load_material_fn)
	return
}

parse_obj :: proc {
	parse_obj_ref,
	parse_obj_val,
	parse_obj_alloc,
}

SceneBuilder :: struct {
	vertices:            [dynamic]types.Vec4,
	texture_coordinates: [dynamic]types.Vec2,
	normals:             [dynamic]types.Vec3,
}

scene_builder_destroy :: proc(builder: ^SceneBuilder) {
	delete(builder.vertices)
	delete(builder.texture_coordinates)
	delete(builder.normals)
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

parse_vertex :: proc(iter: ^ObjTokenIter, builder: ^SceneBuilder) -> (v: render.MeshVertex, ok: bool) {
	// Start by getting the position
	next_token := common.token_iter_next(iter) or_return
	if next_token.type != .Integer do return
	index := next_token.value.(i32)
	assert(index > 0 && int(index) <= len(builder.vertices))

	// We only need x, y, and z.
	v.position = builder.vertices[index - 1].xyz

	next_token = common.token_iter_next(iter) or_return
	if next_token.type != .Slash do return

	// The vertex coordinates are optional, and default to {0, 0}
	next_token = common.token_iter_next(iter) or_return
	if next_token.type == .Integer {
		index = next_token.value.(i32)
		assert(index > 0 && int(index) <= len(builder.texture_coordinates))
		v.texture_coordinates = builder.texture_coordinates[index - 1]

		next_token = common.token_iter_next(iter) or_return
	}

	if next_token.type != .Slash do return

	// Finally, get the normal
	next_token = common.token_iter_next(iter) or_return
	if next_token.type != .Integer do return
	index = next_token.value.(i32)
	assert(index > 0 && int(index) <= len(builder.normals))
	v.normal = builder.normals[index - 1]

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
	scene: ^render.Scene,
	load_material_data: LoadMaterialDataFn,
) -> (
	ok: bool,
) {
	log.infof("Loading material from file: {}", material_file_name)
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
		scene.materials[mat_name] = mat
	}

	return true
}
