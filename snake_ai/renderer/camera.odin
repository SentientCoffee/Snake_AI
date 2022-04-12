package renderer

import "../math"

import "core:math/linalg"

Camera :: struct {
    projection : math.Mat4x4,
    transform  : math.Transform,
}

init_camera :: proc(using camera : ^Camera, left, right, top, bottom : f32, near : f32 = -0.1, far : f32 = 1000.0) {
    using math
    transform = {
        position = { 0, 0, 0 },
        rotation = create_rotation_radians({ 0, 0, 0 }),
        scale    = { 1, 1, 1 },
    }
    projection = linalg.matrix_ortho3d(left, right, bottom, top, near, far)
}

get_view_matrix :: proc(using camera : Camera) -> math.Mat4x4 {
    return linalg.matrix4_inverse(math.get_local_transform(transform))
}

get_view_projection_matrix :: proc(using camera : Camera) -> math.Mat4x4 {
    return projection * get_view_matrix(camera)
}
