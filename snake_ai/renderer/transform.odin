package renderer

import "core:math/linalg"

Rotation_Degrees :: struct {
    euler_angles : Vector3,
}

Rotation_Radians :: struct {
    euler_angles : Vector3,
}

Rotation :: union {
    Rotation_Degrees,
    Rotation_Radians,
}

Transform :: struct {
    position : Vector3,
    rotation : Rotation,
    scale    : Vector3,
    parent   : Mat4x4,
}

create_rotation_degrees :: proc(euler_angles : Vector3) -> (rot : Rotation_Degrees) {
    rot.euler_angles = euler_angles
    return
}

create_rotation_radians :: proc(euler_angles : Vector3) -> (rot : Rotation_Radians) {
    rot.euler_angles = euler_angles
    return
}

get_local_transform :: proc(using t : Transform) -> Mat4x4 {
    using linalg
    translate := matrix4_translate(position)
    rot : Rotation_Radians
    switch r in rotation {
        case Rotation_Degrees: rot.euler_angles = Vector3{ radians(r.euler_angles.x), radians(r.euler_angles.y), radians(r.euler_angles.z), }
        case Rotation_Radians: rot.euler_angles = r.euler_angles
        case:
    }

    rotate := matrix4_from_quaternion(quaternion_from_pitch_yaw_roll(rot.euler_angles.x, rot.euler_angles.y, rot.euler_angles.z))
    scaling := matrix4_scale(scale)

    return translate * rotate * scaling
}

get_world_transform :: proc(using t : Transform) -> Mat4x4 {
    local := get_local_transform(t)
    return parent * local
}
