package input

import "../types"

InputState :: struct {
	movement: types.Vec3,
	mouse:    struct {
		position:      types.Vec2,
		offset:        types.Vec2,
		scroll_offset: f32,
	},
}

input_state: InputState
