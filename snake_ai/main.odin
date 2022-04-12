package snake_ai

import app "application"
import "game"
import "input"
import log "logging"
import "renderer"

import "core:mem"

WIDTH  :: 1280
HEIGHT :: 720
TITLE  :: "Snek AI"

main :: proc() {
    ctx := context
    log.create_console_logger(&ctx, log.Level_Debug)
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
        log.error("Temp allocator", "free_all == {}", err)
    }
}
