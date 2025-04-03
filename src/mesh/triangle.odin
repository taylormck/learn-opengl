package mesh

import "../types"

NUM_TRIANGLE_VERTICES :: 3

TRIANGLE_VERTEX_POSITIONS := [NUM_TRIANGLE_VERTICES]types.Vec3 {
    {-0.5, -0.5, 0}, // bottom left
    {0.5, -0.5, 0}, // bottom right
    {0, 0.5, 0}, // top
}

TRIANGLE_VERTEX_COLORS := [NUM_TRIANGLE_VERTICES]types.Vec3 {
    {1, 0, 0}, // bottom left
    {0, 1, 0}, // bottom right
    {0, 0, 1}, // top
}

TRIANGLE_TEXTURE_COORDS := [NUM_TRIANGLE_VERTICES]types.Vec2 {
    {0, 0}, // bottom left
    {1, 0}, // bottom right
    {0.5, 1}, // top
}
