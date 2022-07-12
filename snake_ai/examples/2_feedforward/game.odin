package feedforward2

import log "engine:logging"

g_neural_network : Neural_Network

start :: proc(width, height : int) {
    m1 := make_matrix(2, 3)
    m2 := make_matrix(3, 2)

    m1.values = {
        6, 7, 0,
        7, 2, 6,
    }
    m2.values = {
        5, 3,
        1, 1,
        5, 1,
    }

    m3 := matrix_multiply(m1, m2)
    log.info("Multiply", "m3 is a {}x{} matrix: {}", m3.rows, m3.cols, m3.values)
    m4 := matrix_transpose_new(m3)
    log.info("Transpose", "m4 is a {}x{} matrix: {}", m4.rows, m4.cols, m4.values)
    matrix_transpose_inplace(&m4)
    log.info("Transpose", "m4 is a {}x{} matrix: {}", m4.rows, m4.cols, m4.values)


    // g_neural_network = make_neural_network(2, 2, 1)
    // input := []f32{ 1, 0 }
    // output := nn_feed_forward(g_neural_network, input)
    // log.info("OUTPUT", "{}", output)
}

end :: proc() {

}

update :: proc() {

}

render :: proc() {

}
