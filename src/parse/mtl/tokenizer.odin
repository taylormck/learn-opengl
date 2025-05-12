package mtl

import "../common"
import "core:log"
import "core:strconv"


MaterialTokenType :: enum {
	MaterialName,
	Shininess,
	Ambient,
	Diffuse,
	Specular,
	Emissive,
	OpticalDensity,
	IlluminationModel,
	Transparency,
	TransmissionFilter,
	DiffuseMap,
	BumpMap,
	SpecularMap,
	SpecularHighlightMap,
	AlphaMap,
	DisplacementMap,
	Decal,
	Integer,
	Float,
	String,
	EOF,
}

MaterialTokenValue :: union {
	i32,
	f32,
	string,
}

MaterialToken :: struct {
	type:  MaterialTokenType,
	value: MaterialTokenValue,
}

string_iter_get_next_token :: proc(iter: ^common.StringIter) -> MaterialToken {
	start_index := iter.reader.i
	end_index := iter.reader.i

	find_next_token_start: for !common.string_iter_is_at_end(iter) {
		current := common.string_iter_next(iter)
		switch current {
		case '#':
			for current != '\n' {
				current = common.string_iter_next(iter)
				if common.string_iter_is_at_end(iter) do break
			}

		case 'A' ..= 'Z', 'a' ..= 'z':
			start_index = iter.reader.i - 1
			offset: i64 = 1

			for !common.string_iter_is_at_end(iter) {
				current = common.string_iter_next(iter)
				if !common.is_valid_string_char(current) do break
				offset += 1
			}

			end_index = start_index + offset
			break find_next_token_start

		case '0' ..= '9':
			start_index = iter.reader.i - 1
			offset: i64 = 1

			for !common.string_iter_is_at_end(iter) {
				current = common.string_iter_next(iter)
				if !common.is_valid_numerical_char(current) do break
				offset += 1
			}

			end_index = start_index + offset
			break find_next_token_start
		}
	}

	value := common.string_iter_slice(iter, start_index, end_index)

	switch value {
	case "newmtl":
		return MaterialToken{type = .MaterialName}
	case "Ns":
		return MaterialToken{type = .Shininess}
	case "Ka":
		return MaterialToken{type = .Ambient}
	case "Kd":
		return MaterialToken{type = .Diffuse}
	case "Ks":
		return MaterialToken{type = .Specular}
	case "Ke":
		return MaterialToken{type = .Emissive}
	case "Ni":
		return MaterialToken{type = .OpticalDensity}
	case "illum":
		return MaterialToken{type = .IlluminationModel}
	case "d", "Tr":
		return MaterialToken{type = .Transparency}
	case "Tf":
		return MaterialToken{type = .TransmissionFilter}
	case "map_Kd":
		return MaterialToken{type = .DiffuseMap}
	case "map_Bump", "bump":
		return MaterialToken{type = .BumpMap}
	case "map_Ks":
		return MaterialToken{type = .SpecularMap}
	case "map_Ns":
		return MaterialToken{type = .SpecularHighlightMap}
	case "map_d":
		return MaterialToken{type = .AlphaMap}
	case "disp":
		return MaterialToken{type = .DisplacementMap}
	case "decal":
		return MaterialToken{type = .Decal}
	case:
		switch {
		case len(value) == 0:
			return MaterialToken{type = .EOF}
		case common.is_float(value):
			val, ok := strconv.parse_f32(value)
			if !ok {
				log.errorf("Failed to parse float: {}", value)
				return string_iter_get_next_token(iter)
			}
			return MaterialToken{type = .Float, value = val}
		case common.is_integer(value):
			val, ok := strconv.parse_int(value)
			if !ok {
				log.errorf("Failed to parse integer: {}", value)
				return string_iter_get_next_token(iter)
			}
			return MaterialToken{type = .Integer, value = i32(val)}
		case:
			return MaterialToken{type = .String, value = value}
		}
	}
}
