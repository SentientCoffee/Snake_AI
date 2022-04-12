package renderer

import "../math"

import gl "vendor:OpenGL"

Color :: math.Vector4

Buffer_Usage :: enum u32 {
    Stream_Draw  = gl.STREAM_DRAW,
    Stream_Read  = gl.STREAM_READ,
    Stream_Copy  = gl.STREAM_COPY,

    Static_Draw  = gl.STATIC_DRAW,
    Static_Read  = gl.STATIC_READ,
    Static_Copy  = gl.STATIC_COPY,

    Dynamic_Draw = gl.DYNAMIC_DRAW,
    Dynamic_Read = gl.DYNAMIC_READ,
    Dynamic_Copy = gl.DYNAMIC_COPY,
};

Clear_Flags :: enum u32 {
    Depth      = gl.DEPTH_BUFFER_BIT,
    Color      = gl.COLOR_BUFFER_BIT,
    Stencil    = gl.STENCIL_BUFFER_BIT,
    No_Color   = Depth | Stencil,          // gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT
    No_Depth   = Color | Stencil,          // gl.COLOR_BUFFER_BIT | gl.STENCIL_BUFFER_BIT
    No_Stencil = Color | Depth,            // gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT
    All        = Color | Depth | Stencil,  // gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT
};

Cull_Face :: enum u32 {
    None  = 0,
    Front = gl.FRONT,
    Back  = gl.BACK,
    Both  = gl.FRONT_AND_BACK,
};

Destination_Factor :: enum u32 {
    Zero                         = gl.ZERO,
    One                          = gl.ONE,
    Source_Colour                = gl.SRC_COLOR,
    One_Minus_Source_Colour      = gl.ONE_MINUS_SRC_COLOR,
    Source_Alpha                 = gl.SRC_ALPHA,
    One_Minus_Source_Alpha       = gl.ONE_MINUS_SRC_ALPHA,
    Destination_Alpha            = gl.DST_ALPHA,
    One_Minus_Destination_Alpha  = gl.ONE_MINUS_DST_ALPHA,
    Destination_Colour           = gl.DST_COLOR,
    One_Minus_Destination_Colour = gl.ONE_MINUS_DST_COLOR,
    Constant_Colour              = gl.CONSTANT_COLOR,
    One_Minus_Constant_Colour    = gl.ONE_MINUS_CONSTANT_COLOR,
    Constant_Alpha               = gl.CONSTANT_ALPHA,
    One_Minus_Constant_Alpha     = gl.ONE_MINUS_CONSTANT_ALPHA,
};

Source_Factor :: enum u32 {
    Zero                         = gl.ZERO,
    One                          = gl.ONE,
    Source_Color                 = gl.SRC_COLOR,
    One_Minus_Source_Color       = gl.ONE_MINUS_SRC_COLOR,
    Source_Alpha                 = gl.SRC_ALPHA,
    One_Minus_Source_Alpha       = gl.ONE_MINUS_SRC_ALPHA,
    Destination_Alpha            = gl.DST_ALPHA,
    One_Minus_Destination_Alpha  = gl.ONE_MINUS_DST_ALPHA,
    Destination_Colour           = gl.DST_COLOR,
    One_Minus_Destination_Colour = gl.ONE_MINUS_DST_COLOR,
    Source_Alpha_Saturate        = gl.SRC_ALPHA_SATURATE,
    Constant_Colour              = gl.CONSTANT_COLOR,
    One_Minus_Constant_Colour    = gl.ONE_MINUS_CONSTANT_COLOR,
    Constant_Alpha               = gl.CONSTANT_ALPHA,
    One_Minus_Constant_Alpha     = gl.ONE_MINUS_CONSTANT_ALPHA,
};

clear_screen :: proc "c" (flags := Clear_Flags.All) {
    gl.Clear(cast(u32) flags)
}

draw_indexed :: proc"c" (mesh : ^Mesh) {
    gl.DrawElements(gl.TRIANGLES, cast(i32) mesh.index_buffer.index_count, gl.UNSIGNED_INT, nil);
}

enable_blending :: proc "c" (enabled : bool) {
    if enabled { gl.Enable(gl.BLEND)  }
    else       { gl.Disable(gl.BLEND) }
}

enable_depth_test :: proc "c" (enabled : bool) {
    if enabled { gl.Enable(gl.DEPTH_TEST)  }
    else       { gl.Disable(gl.DEPTH_TEST) }
}
enable_depth_mask :: proc "c" (flag : bool) {
    gl.DepthMask(flag);
}

set_blend_function :: proc { set_blend_function_normal, set_blend_function_separate }
set_blend_function_normal :: proc "c" (source_factor : Source_Factor, destination_factor : Destination_Factor) {
    gl.BlendFunc(cast(u32) source_factor, cast(u32) destination_factor);
}
set_blend_function_separate :: proc "c" (
    colour_source_factor : Source_Factor, colour_destination_factor : Destination_Factor,
    alpha_source_factor  : Source_Factor, alpha_destination_factor  : Destination_Factor,
) {
    gl.BlendFuncSeparate(cast(u32) colour_source_factor, cast(u32) colour_destination_factor, cast(u32) alpha_source_factor, cast(u32) alpha_destination_factor);
}

set_clear_color       :: proc { set_clear_color_color, set_clear_color_f32 }
set_clear_color_color :: proc "c" (c : Color)        { gl.ClearColor(c.r, c.g, c.b, c.a) }
set_clear_color_f32   :: proc "c" (r, g, b, a : f32) { gl.ClearColor(  r,   g,   b,   a) }

set_cull_face :: proc "c" (face : Cull_Face) {
    if face == .None {
        gl.Disable(gl.CULL_FACE);
    }
    else {
        gl.Enable(gl.CULL_FACE);
        gl.CullFace(cast(u32) face);
    }
}

set_viewport :: proc "c" (x, y, w, h : i32) {
    gl.Viewport(x, y, w, h)
    gl.Scissor(x, y, w, h)
}
