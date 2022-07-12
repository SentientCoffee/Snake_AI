package perceptron1

// import app "engine:application"
import "engine:input"
// import log "engine:logging"
import "engine:math"
import "engine:renderer"

g_brain  : Perceptron
g_points : [100]Point
g_training_index : int
g_started := false

@(private) window_width  : int = 0
@(private) window_height : int = 0

@(private) point_min : math.Vector2 = { -1, -1 }
@(private) point_max : math.Vector2 = {  1,  1 }

line_func :: proc(x : f32) -> f32 { return -0.3 * x - 0.2 }

start :: proc(width, height : int) {
    window_width  = width
    window_height = height

    g_training_index = 0
    g_brain = make_perceptron(num_weights = 3, learning_rate = 0.008)
    for p in &g_points {
        p = make_random_point(point_min, point_max, line_func)
    }
}

end :: proc() {
    delete_perceptron(g_brain)
}

update :: proc() {
    if input.key_down(.Space) { g_started = true }
    if !g_started { return }

    p := g_points[g_training_index]
    perceptron_train(&g_brain, []f32{ p.position.x, p.position.y, p.bias }, p.target)

    g_training_index += 1
    if g_training_index >= len(g_points) { g_training_index = 0 }
}

render :: proc() {
    draw_real_line()
    draw_perceptron_line(g_brain)

    for p, i in g_points {
        guess := perceptron_guess(g_brain, []f32{ p.position.x, p.position.y, p.bias })
        fill_color   := renderer.Color{ 0.8, 0.2, 0.3, 1.0 }
        stroke_color := renderer.Color{ 0.0, 0.0, 0.0, 1.0 }

        if guess == p.target { fill_color   = { 0.2, 0.8, 0.3, 1.0 } }
        if p.target > 0      { stroke_color = { 1.0, 1.0, 1.0, 1.0 } }

        draw_point(point = p, z_index = f32(-i) - 0.5, thickness = 0.3, color = stroke_color)
        draw_point(point = p, z_index = f32(-i), radius = 18.0, color = fill_color)
    }
}

draw_point :: proc(using point : Point, z_index : f32 = 0.0, radius : f32 = 20.0, thickness : f32 = 1.0, color : renderer.Color = { 0.0, 0.0, 0.0, 1.0 }, fade : f32 = 0.0) {
    pos_x := math.remap(point.position.x, point_min.x, point_max.x, 0.0, f32(window_width))
    pos_y := math.remap(point.position.y, point_min.y, point_max.y, 0.0, f32(window_height))

    renderer.draw_circle({
        position  = { pos_x, pos_y, z_index },
        radius    = radius,
        thickness = thickness,
        color     = color,
        fade      = fade,
    })
}

draw_real_line :: proc() {
    start_pos := math.Vector3 {
        math.remap(      f32(-1.0), point_min.x, point_max.x, 0.0, f32(window_width)),
        math.remap(line_func(-1.0), point_min.y, point_max.y, 0.0, f32(window_height)),
        -150,
    }
    end_pos := math.Vector3 {
        math.remap(      f32(1.0), point_min.x, point_max.x, 0.0, f32(window_width)),
        math.remap(line_func(1.0), point_min.y, point_max.y, 0.0, f32(window_height)),
        -150,
    }

    renderer.draw_line({
        start     = start_pos,
        end       = end_pos,
        thickness = 1.8,
        color     = { 0.7, 0.8, 0.3, 1.0 },
    })
}

draw_perceptron_line :: proc(p : Perceptron) {
    perceptron_line_func :: proc(p : Perceptron, x : f32) -> f32 {
        return -(p.weights[2] / p.weights[1]) - (p.weights[0] / p.weights[1]) * x
    }

    start_pos := math.Vector3{
        math.remap(                    f32(-1.0), point_min.x, point_max.x, 0.0, f32(window_width)),
        math.remap(perceptron_line_func(p, -1.0), point_min.y, point_max.y, 0.0, f32(window_height)),
        -150,
    }
    end_pos := math.Vector3 {
        math.remap(                    f32(1.0), point_min.x, point_max.x, 0.0, f32(window_width)),
        math.remap(perceptron_line_func(p, 1.0), point_min.y, point_max.y, 0.0, f32(window_height)),
        -150,
    }

    renderer.draw_line({
        start     = start_pos,
        end       = end_pos,
        thickness = 1.8,
        color     = { 0.7, 0.3, 0.8, 1.0 },
    })
}
