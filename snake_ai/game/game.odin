package game

// import log "../logging"
import "../math"
import "../renderer"

import maths "core:math"

BOUNDS_WIDTH  :: 24
BOUNDS_HEIGHT :: 18

@(private) window_width  : int = 0
@(private) window_height : int = 0

main_sim : ^Simulation

start :: proc(width, height : int) {
    window_width  = width
    window_height = height

    main_sim = new_simulation(BOUNDS_WIDTH, BOUNDS_HEIGHT)
}

end :: proc() {
    free_simulation(main_sim)
}

update :: proc() {
    update_sim(main_sim)
}

render :: proc() {
    aspect      :: f32(BOUNDS_WIDTH) / f32(BOUNDS_HEIGHT)
    back_y      := f32(window_height) / 2.0
    back_height := f32(window_height) - (40.0 * 2)
    back_width  := maths.floor(back_height * aspect)
    back_x      := f32(window_width) - 40.0 - (back_width / 2.0)

    back := renderer.Quad{
        position   = math.Vector3{ back_x, back_y, -10.0 },
        dimensions = math.Vector2{ back_width, back_height },
        tint       = renderer.Color{ 0.2, 0.2, 0.3, 1.0 },
    }

    cell_width  := back_width  / BOUNDS_WIDTH
    cell_height := back_height / BOUNDS_HEIGHT
    x_zero := back_x - (back_width  / 2.0) + (cell_width  / 2.0)
    y_zero := back_y - (back_height / 2.0) + (cell_height / 2.0)

    food_x := x_zero + (main_sim.food_position.x * cell_width)
    food_y := y_zero + (main_sim.food_position.y * cell_height)
    food := renderer.Quad{
        position   = math.Vector3{ food_x, food_y, 0.0 },
        dimensions = math.Vector2{ cell_width - 10.0, cell_height - 10.0 },
        tint       = renderer.Color{ 0.8, 0.2, 0.3, 1.0 },
    }

    head_x := x_zero + (main_sim.snake.head_position.x * cell_width)
    head_y := y_zero + (main_sim.snake.head_position.y * cell_height)

    snek_head := renderer.Quad{
        position   = math.Vector3{ head_x, head_y, 0.0 },
        dimensions = math.Vector2{ cell_width - 5.0, cell_height - 5.0 },
        tint       = renderer.Color{ 0.2, 0.8, 0.3, 1.0 },
    }

    snek_body := renderer.Quad{
        position   = math.Vector3{ x_zero, y_zero, 0.0 },
        dimensions = math.Vector2{ cell_width - 10.0, cell_height - 10.0 },
        tint       = renderer.Color{ 0.2, 0.8, 0.3, 1.0 },
    }

    renderer.draw_quad(back)
    renderer.draw_quad(food)
    renderer.draw_quad(snek_head)

    for pos in main_sim.snake.real_body_positions {
        body_x := x_zero + (pos.x * cell_width)
        body_y := y_zero + (pos.y * cell_height)
        snek_body.position = math.Vector3{ body_x, body_y, 0.0 }
        renderer.draw_quad(snek_body)
    }
}
