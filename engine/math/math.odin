package game_math

import "core:math"
import "core:math/linalg"

Vector2    :: linalg.Vector2f32
Vector3    :: linalg.Vector3f32
Vector4    :: linalg.Vector4f32
Quaternion :: linalg.Quaternionf32

Mat4x4 :: linalg.Matrix4x4f32
Mat3x3 :: linalg.Matrix3x3f32

Mat4x4_Identity :: linalg.MATRIX4F32_IDENTITY
Mat3x3_Identity :: linalg.MATRIX3F32_IDENTITY

// --------------------------------------------

acos  :: math.acos

floor :: math.floor

matrix_ortho3d  :: linalg.matrix_ortho3d
matrix4_inverse :: linalg.matrix4_inverse

vector_cross   :: linalg.vector_cross
vector_dot     :: linalg.vector_dot
vector_length  :: linalg.vector_length
vector_length2 :: linalg.vector_length2
