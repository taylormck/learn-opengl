package input

import "../types"

InputState :: struct {
	movement:     types.Vec3,
	mouse:        struct {
		position:      types.Vec2,
		offset:        types.Vec2,
		scroll_offset: f32,
	},
	pressed_keys: KeySet,
}

input_state: InputState

KeySet :: bit_set[Keys]

Keys :: enum {
	B,
	Space,
}
