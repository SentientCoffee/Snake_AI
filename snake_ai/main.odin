package snake_ai

import app "application"
import "input"
import log "logging"
import "renderer"

import "core:mem"
import "core:runtime"

WIDTH  :: 1280
HEIGHT :: 720
TITLE  :: "Snek AI"

g_context : runtime.Context

main :: proc() {
    ctx := context
    log.create_console_logger(&ctx, log.Level_Debug)
    context = ctx

    window := app.create_window(WIDTH, HEIGHT, TITLE)
    defer app.destroy_window(window)

    renderer.init_renderer(WIDTH, HEIGHT)
    defer renderer.deinit_renderer()

    for !window.closed {
        if err := mem.free_all(context.temp_allocator); err != .None {
            log.error("Temp allocator", "free_all == {}", err)
        }

        input.poll_for_events()
        app.update_time()

        renderer.set_clear_color(0.3, 0.2, 0.8, 1.0)
        renderer.clear_screen()

        back := renderer.Quad{
            position   = renderer.Vector3{ 784, 360, -1 },
            dimensions = renderer.Vector2{ 912, 684 },
            tint       = renderer.Color{ 0.2, 0.2, 0.3, 1.0 },
        }

        snek := renderer.Quad{
            position   = renderer.Vector3{ 210.0, 670.0, 0.0 },
            dimensions = renderer.Vector2{ 400.0, 70.0 },
            tint       = renderer.Color{ 0.2, 0.8, 0.3, 1.0 },
        }

        renderer.draw_quad(back)
        renderer.draw_quad(snek)

        app.window_swap_buffers(window)
    }
}
