package feedforward2

import "engine:math"

Neural_Network :: struct {
    input_nodes, output_nodes, hidden_nodes : int,
    weights_ih, weights_ho : Matrix,
}

make_neural_network :: proc(input, hidden, output : int) -> (nn : Neural_Network) {
    nn = Neural_Network {
        input_nodes  = input,
        hidden_nodes = hidden,
        output_nodes = output,
        weights_ih   = make_matrix(hidden, input),
        weights_ho   = make_matrix(output, hidden),
    }
    nn_randomize_weights(&nn)
    return
}

delete_neural_network :: proc(using nn : ^Neural_Network) {
    delete_matrix(weights_ih)
    delete_matrix(weights_ho)
}

nn_feed_forward :: proc(nn : Neural_Network, input : []f32) -> (output : int) {

    return
}

nn_randomize_weights :: proc(nn : ^Neural_Network) {
    for w in &nn.weights_ih.values {
        w = math.random_f32(-1.0, 1.0)
    }
    for w in &nn.weights_ho.values {
        w = math.random_f32(-1.0, 1.0)
    }
}
