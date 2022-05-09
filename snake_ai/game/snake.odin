package game

import "snake_ai:math"

Snake_Direction :: enum {
    Up    = 0,
    Down  = 180,
    Left  = 270,
    Right = 90,
}

Snake :: struct {
    head_position        : math.Vector2,
    head_direction       : Snake_Direction,
    body_size            : int,
    sim_body_positions   : [dynamic]math.Vector2,
    real_body_positions  : [dynamic]math.Vector2,
    real_body_directions : [dynamic]Snake_Direction,
}

new_snake :: proc(start_position := math.Vector2{ 1, 0 }) -> (snake : ^Snake) {
    snake = new(Snake)

    snake.head_position        = start_position
    snake.head_direction       = .Right
    snake.body_size            = 1
    snake.real_body_positions  = make([dynamic]   math.Vector2, 0, 100)
    snake.sim_body_positions   = make([dynamic]   math.Vector2, 0, 100)
    snake.real_body_directions = make([dynamic]Snake_Direction, 0, 100)

    append(&snake.real_body_positions, start_position + math.Vector2{ -1, 0 })
    append(&snake.real_body_directions, Snake_Direction.Right)  // @Note: ols dies if I use implicit selection here. - 11 Apr 2022 18:00

    return
}

move_snake :: proc(using snake : ^Snake, sim_move := false) {
    if !sim_move {
        insert_at(&real_body_positions,  0, head_position)
        insert_at(&real_body_directions, 0, head_direction)
    }
    else {
        append(&sim_body_positions, head_position)
    }

    switch head_direction {
        case .Right: head_position += math.Vector2{ +1,  0 }
        case .Left:  head_position += math.Vector2{ -1,  0 }
        case .Down:  head_position += math.Vector2{  0, +1 }
        case .Up:    head_position += math.Vector2{  0, -1 }
    }

    if !sim_move {
        if len(real_body_positions) > body_size  { unordered_remove(&real_body_positions, len(real_body_positions) - 1) }
        if len(real_body_directions) > body_size { unordered_remove(&real_body_directions, len(real_body_directions) - 1) }
    }
}

check_self_collision :: proc(using snake : ^Snake) -> bool {
    for pos in real_body_positions {
        if pos == head_position {
            return true
        }
    }
    return false
}

check_wall_collision :: proc(using snake : ^Snake, bounds : math.Vector2) -> bool {
    return head_position.x < 0 ||
           head_position.y < 0 ||
           head_position.x >= bounds.x ||
           head_position.y >= bounds.y
}

undo_sim_moves :: proc(using snake : ^Snake) {
    head_position = sim_body_positions[0]
    clear(&sim_body_positions)
}

free_snake :: proc(using snake : ^Snake) {
    delete(snake.sim_body_positions)
    delete(snake.real_body_positions)
    delete(snake.real_body_directions)
    free(snake)
}
