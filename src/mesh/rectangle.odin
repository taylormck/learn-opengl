package mesh

import "../types"

NUM_RECTANGLE_VERTICES :: 4

RECTANGLE_VERTEX_POSITIONS := [NUM_RECTANGLE_VERTICES]types.Vec3 {
    {0.5, 0.5, 0.0}, // top right
    {0.5, -0.5, 0.0}, // bottom right
    {-0.5, 0.5, 0.0}, // top left
    {-0.5, -0.5, 0.0}, // bottom left
}

RECTANGLE_VERTEX_COLORS := [NUM_RECTANGLE_VERTICES]types.Vec3 {
    {1, 0, 0}, // top right
    {0, 1, 0}, // bottom right
    {1, 1, 0}, // top left
    {0, 0, 1}, // bottom left
}

RECTANGLE_TEXTURE_COORDS := [NUM_RECTANGLE_VERTICES]types.Vec2 {
    {1, 1}, // top right
    {1, 0}, // bottom right
    {0, 1}, // top left
    {0, 0}, // bottom left
}

RECTANGLE_INDICES := [2]types.Vec3u{{0, 1, 2}, {1, 3, 2}}
