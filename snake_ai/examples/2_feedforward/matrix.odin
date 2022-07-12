package feedforward2

import log "engine:logging"

Matrix :: struct {
    rows, cols : int,
    values     : []f32,
}

// -----------------------------------------------------------------------------------

matrix_add_scalar        :: proc { matrix_add_scalar_inplace, matrix_add_scalar_new }
matrix_multiply_scalar   :: proc { matrix_multiply_scalar_inplace, matrix_multiply_scalar_new }
matrix_multiply_hadamard :: proc { matrix_multiply_hadamard_inplace, matrix_multiply_hadamard_new }
matrix_transpose         :: proc { matrix_transpose_inplace, matrix_transpose_new }

// -----------------------------------------------------------------------------------

make_matrix :: proc(rows, cols : int) -> (m : Matrix) {
    m = Matrix {
        rows = rows,
        cols = cols,
        values = make([]f32, rows * cols),
    }
    return
}
delete_matrix :: proc(using m : Matrix) {
    delete(values)
}

matrix_add_scalar_inplace :: proc(using m : ^Matrix, scalar : f32) {
    for v in &values {
        v += scalar
    }
}
matrix_add_scalar_new :: proc(m1 : Matrix, scalar : f32) -> (m2 : Matrix) {
    m2 = make_matrix(m1.rows, m1.cols)
    for v, i in &m2.values {
        v = m1.values[i] + scalar
    }
    return
}

matrix_add_matrix :: proc(m1, m2 : Matrix) -> (m : Matrix) {
    log.assert(m1.rows == m2.rows, "Matrix add (matrix)", "Cannot add matrices together, dimensions do not match (m1.rows != m2.rows)")
    log.assert(m1.cols == m2.cols, "Matrix add (matrix)", "Cannot add matrices together, dimensions do not match (m1.cols != m2.cols)")

    m = make_matrix(m1.rows, m1.cols)
    for v, i in &m.values {
        v = m1.values[i] + m2.values[i]
    }
    return
}

matrix_multiply_scalar_inplace :: proc(using m : ^Matrix, scalar : f32) {
    for v in &values {
        v *= scalar
    }
}
matrix_multiply_scalar_new :: proc(using m1 : Matrix, scalar : f32) -> (m2 : Matrix) {
    m2 = make_matrix(m1.rows, m1.cols)
    for v, i in &m2.values {
        v = m1.values[i] + scalar
    }
    return
}

matrix_multiply_hadamard_inplace :: proc(m1 : ^Matrix, m2 : Matrix) {
    log.assert(m1.rows == m2.rows, "Matrix multiply (Hadamard)", "Cannot multiply matrices together, dimensions do not match (m1.rows != m2.rows)")
    log.assert(m1.cols == m2.cols, "Matrix multiply (Hadamard)", "Cannot multiply matrices together, dimensions do not match (m1.cols != m2.cols)")

    for v, i in &m1.values {
        v *= m2.values[i]
    }
    return
}
matrix_multiply_hadamard_new :: proc(m1, m2 : Matrix) -> (m : Matrix) {
    log.assert(m1.rows == m2.rows, "Matrix multiply (Hadamard)", "Cannot multiply matrices together, dimensions do not match (m1.rows != m2.rows)")
    log.assert(m1.cols == m2.cols, "Matrix multiply (Hadamard)", "Cannot multiply matrices together, dimensions do not match (m1.cols != m2.cols)")

    m = make_matrix(m1.rows, m1.cols)
    for v, i in &m.values {
        v = m1.values[i] * m2.values[i]
    }
    return
}

matrix_multiply :: proc(m1, m2 : Matrix) -> (m : Matrix) {
    log.assert(m1.cols == m2.rows, "Matrix multiply", "Cannot multiply matrices together, dimensions do not match (m1.cols != m2.rows)")

    m = make_matrix(m1.rows, m2.cols)
    for row in 0 ..< m.rows {
        for col in 0 ..< m.cols {
            for offset in 0 ..< m1.cols {  // @Note: m1.cols == m2.rows, either works here
                m_index  := row    * m.cols  + col
                m1_index := row    * m1.cols + offset
                m2_index := offset * m2.cols + col
                m.values[m_index] += m1.values[m1_index] * m2.values[m2_index]
            }
        }
    }
    return
}

matrix_transpose_inplace :: proc(using m1 : ^Matrix) {
    old_values := m1.values
    defer delete(old_values)

    new_values := make(type_of(m1.values), len(m1.values))
    for row in 0 ..< m1.cols {
        for col in 0 ..< m1.rows {
            normal      := row * m1.rows + col
            transponsed := col * m1.rows + row
            new_values[transponsed] = old_values[normal]
        }
    }

    m1.values = new_values
}
matrix_transpose_new :: proc(m1 : Matrix) -> (m : Matrix) {
    m = make_matrix(m1.cols, m1.rows)
    for row in 0 ..< m.rows {
        for col in 0 ..< m.cols {
            normal      := row * m.cols + col
            transponsed := col * m.cols + row
            m.values[transponsed] = m1.values[normal]
        }
    }
    return
}
