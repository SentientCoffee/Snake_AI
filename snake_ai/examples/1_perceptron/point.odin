package perceptron1

import "engine:math"

Point :: struct {
    position : math.Vector2,
    bias     : f32,
    target   : int,
}

make_random_point :: proc(low, high : math.Vector2, target_func : proc(f32) -> f32) -> (p : Point) {
    x := math.random_f32(low.x, high.x)
    y := math.random_f32(low.y, high.y)

    target_y  := target_func(x)
    p.target   = 1 if y > target_y else -1
    p.position = { x, y }
    p.bias = 1
    return
}
