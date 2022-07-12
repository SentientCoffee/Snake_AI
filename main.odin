package snake_ai

import app "engine:application"
import     "engine:input"
import log "engine:logging"
import     "engine:renderer"

// import game "game:examples/1_perceptron"
import game "game:examples/2_feedforward"

import "core:mem"

WIDTH  :: 1600
HEIGHT :: 900
TITLE  :: "Snek AI"

main :: proc() {
    ctx := context
    log.create_console_logger(&ctx, log.Level_Info)
    context = ctx

    window := app.create_window(WIDTH, HEIGHT, TITLE)
    defer app.destroy_window(window)

    renderer.init(WIDTH, HEIGHT)
    defer renderer.destroy()

    game.start(WIDTH, HEIGHT)
    defer game.end()

    for !window.closed {
        free_temp_storage()

        input.poll_for_events()
        app.update_time()

        game.update()

        renderer.set_clear_color(0.3, 0.2, 0.8, 1.0)
        renderer.clear_screen()

        game.render()

        app.window_swap_buffers(window)
    }
}

free_temp_storage :: proc() {
    if err := mem.free_all(context.temp_allocator); err != .None {
        log.error("Temp allocator", "free_all error: {}", err)
    }
}
