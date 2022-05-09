package perceptron1

import "core:math/rand"

Perceptron :: struct {
    weights       : []f32,
    learning_rate : f32,
}

make_perceptron :: proc(num_weights : int, learning_rate : f32 = 0.01) -> (p : Perceptron) {
    p.weights = make([]f32, num_weights)

    p.learning_rate = learning_rate
    for w in &p.weights {
        w = rand.float32_range(-1.0, 1.0)
    }

    return
}

delete_perceptron :: proc(using p : Perceptron) {
    delete(weights)
}

perceptron_guess :: proc(using p : Perceptron, inputs : []f32) -> (result : int) {
    sum : f32 = 0
    for i in 0 ..< len(weights) {
        sum += inputs[i] * weights[i]
    }

    result = 1 if sum >= 0 else -1
    return
}

perceptron_train :: proc(using p : ^Perceptron, inputs : []f32, target : int) {
    inputs := inputs

    guess := perceptron_guess(p^, inputs)
    error := target - guess

    for i in 0 ..< len(weights) {
        weights[i] += f32(error) * inputs[i] * learning_rate
    }
}
