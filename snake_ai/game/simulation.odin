package game

import app "../application"
import "../input"
import log "../logging"
import "../math"

import "core:math/rand"

MOVE_DELAY :: 0.4

Simulation :: struct {
    alive         : bool,
    snake         : ^Snake,
    bounds        : math.Vector2,
    food_position : math.Vector2,
}

@(private="file") move_timer : f64
@(private="file") input_dir : Snake_Direction

new_simulation :: proc(bounds_width, bounds_height : int) -> (sim : ^Simulation) {
    sim = new(Simulation)

    sim.alive = true
    sim.snake  = new_snake(start_position = math.Vector2{ cast(f32) (bounds_width / 2), cast(f32) (bounds_height / 2) })
    sim.bounds = math.Vector2{ cast(f32) bounds_width, cast(f32) bounds_height }
    move_food(sim)

    return
}

free_simulation :: proc(using sim : ^Simulation) {
    free_snake(snake)
    free(sim)
}

update_sim :: proc(using sim : ^Simulation) {
    if !alive { return }

    new_dir := get_human_input(snake.head_direction)
    if new_dir != snake.head_direction { input_dir = new_dir }
    if move_timer += app.g_time.delta_time; move_timer > MOVE_DELAY {
        log.trace("Update sim", "Current = {}, New = {}", snake.head_direction, new_dir)
        switch snake.head_direction {
            case .Down:  if input_dir != .Up    { snake.head_direction = input_dir }
            case .Up:    if input_dir != .Down  { snake.head_direction = input_dir }
            case .Right: if input_dir != .Left  { snake.head_direction = input_dir }
            case .Left:  if input_dir != .Right { snake.head_direction = input_dir }
        }
        move_timer = 0.0
        move_snake(snake)
    }

    if check_self_collision(snake) || check_wall_collision(snake, bounds) {
        alive = false
        return
    }

    if math.vector_length2(snake.head_position - food_position) < 0.01 {
        snake.body_size += 1
        move_food(sim)
    }
}


get_human_input :: proc(current_dir : Snake_Direction) -> (new_dir : Snake_Direction) {
    new_dir = current_dir
    if input.key_down(.Up_Arrow)    { new_dir = .Up    }
    if input.key_down(.Down_Arrow)  { new_dir = .Down  }
    if input.key_down(.Right_Arrow) { new_dir = .Right }
    if input.key_down(.Left_Arrow)  { new_dir = .Left  }
    return new_dir
}

move_food :: proc(using sim : ^Simulation) {
    food : for {
        food_position = math.Vector2{
            f32(rand.int_max(int(bounds.x))),
            f32(rand.int_max(int(bounds.y))),
        }

        if food_position == snake.head_position { continue food }
        for pos in snake.real_body_positions {
            if food_position == pos { continue food }
        }

        break
    }
}
