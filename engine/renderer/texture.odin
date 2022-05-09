package renderer

when ODIN_DEBUG {
    import log "engine:logging"
}

import gl "vendor:OpenGL"

Internal_Format :: enum u32 {
    None             = 0,

    Red16            = gl.R16,
    Red8             = gl.R8,
    Red16F           = gl.R16F,
    Red32F           = gl.R32F,

    RG8              = gl.RG8,
    RG16             = gl.RG16,
    RG16F            = gl.RG16F,
    RG32F            = gl.RG32F,

    RGB8             = gl.RGB8,
    RGB16            = gl.RGB16,
    RGB16F           = gl.RGB16F,
    RGB32F           = gl.RGB32F,

    RGBA8            = gl.RGBA8,
    RGBA16           = gl.RGBA16,
    RGBA32F          = gl.RGBA32F,
    RGBA16F          = gl.RGBA16F,

    Depth16          = gl.DEPTH_COMPONENT16,
    Depth24          = gl.DEPTH_COMPONENT24,
    Depth32          = gl.DEPTH_COMPONENT32,
    Depth32F         = gl.DEPTH_COMPONENT32F,

    Stencil4         = gl.STENCIL_INDEX4,
    Stencil8         = gl.STENCIL_INDEX8,
    Stencil16        = gl.STENCIL_INDEX16,

    Depth24_Stencil8 = gl.DEPTH24_STENCIL8,
};

Pixel_Format :: enum u32 {
    None          = 0,

    Red           = gl.RED,
    RG            = gl.RG,
    RGB           = gl.RGB,
    RGBA          = gl.RGBA,

    BGR           = gl.BGR,
    BGRA          = gl.BGRA,

    Depth         = gl.DEPTH_COMPONENT,
    Stencil       = gl.STENCIL_INDEX,
    Depth_Stencil = gl.DEPTH_STENCIL,
}

Pixel_Type :: enum u32 {
    Byte           = gl.BYTE,
    Unsigned_Byte  = gl.UNSIGNED_BYTE,
    Short          = gl.SHORT,
    Unsigned_Short = gl.UNSIGNED_SHORT,
    Int            = gl.INT,
    Unsigned_Int   = gl.UNSIGNED_INT,
    UInt24_UInt8   = gl.UNSIGNED_INT_24_8,
    Float          = gl.FLOAT,
}

// TextureFormats :: struct {
//     internal_format : Internal_Format,
//     pixel_format : Pixel_Format,
//     pixel_type : Pixel_Type,
// }


Texture_2D :: struct {
    rendering_id : u32,
    width, height: int,
}

new_texture_2d :: proc(width, height : int, data : rawptr, format := Internal_Format.RGBA8) -> (tex : ^Texture_2D) {
    tex = new(Texture_2D)
    tex.width = width
    tex.height = height

    pixel_format := Pixel_Format.None
    pixel_type := Pixel_Type.Unsigned_Byte
    switch format {
        case .Red16F:                      fallthrough
        case .Red32F: pixel_type = .Float; fallthrough
        case .Red8:                        fallthrough
        case .Red16: pixel_format = .Red

        case .RG16F:                       fallthrough
        case .RG32F: pixel_type = .Float;  fallthrough
        case .RG8:                         fallthrough
        case .RG16: pixel_format = .RG

        case .RGB16F:                      fallthrough
        case .RGB32F: pixel_type = .Float; fallthrough
        case .RGB8:                        fallthrough
        case .RGB16: pixel_format = .RGB

        case .RGBA16F:                      fallthrough
        case .RGBA32F: pixel_type = .Float; fallthrough
        case .RGBA8:                        fallthrough
        case .RGBA16: pixel_format = .RGBA

        case .Depth32F: pixel_type = .Float; fallthrough
        case .Depth16:                       fallthrough
        case .Depth24:                       fallthrough
        case .Depth32: pixel_format = .Depth

        case .Stencil4: fallthrough
        case .Stencil8: fallthrough
        case .Stencil16: pixel_type = .Unsigned_Int; pixel_format = .Stencil

        case .Depth24_Stencil8: pixel_type = .UInt24_UInt8; pixel_format = .Depth_Stencil

        case .None: pixel_format = .None;
    }

    gl.CreateTextures(gl.TEXTURE_2D, 1, &tex.rendering_id)
    gl.TextureStorage2D(tex.rendering_id, 1, cast(u32) format, cast(i32) width, cast(i32) height)

    if(data != nil) {
        gl.TextureSubImage2D(tex.rendering_id, 0, 0, 0, cast(i32) width, cast(i32) height, cast(u32) pixel_format, cast(u32) pixel_type, data)
        gl.GenerateTextureMipmap(tex.rendering_id)
    }

    gl.TextureParameteri(tex.rendering_id, gl.TEXTURE_WRAP_S, cast(i32) gl.REPEAT)
    gl.TextureParameteri(tex.rendering_id, gl.TEXTURE_WRAP_T, cast(i32) gl.REPEAT)
    gl.TextureParameteri(tex.rendering_id, gl.TEXTURE_MIN_FILTER, cast(i32) gl.LINEAR)
    gl.TextureParameteri(tex.rendering_id, gl.TEXTURE_MAG_FILTER, cast(i32) gl.NEAREST)

    return
}

free_texture :: proc(using tex : ^Texture_2D) {
    gl.DeleteTextures(1, &rendering_id)
    free(tex)
}

bind_texture_to_slot :: proc(using tex : ^Texture_2D, slot : u32) {
    if tex != nil {
        when ODIN_DEBUG {
            log.assert(rendering_id != 0, "Texture 2D", "Invalid texture, unable to bind")
        }
        gl.BindTextureUnit(slot, rendering_id)
    }
    else {
        gl.BindTextureUnit(slot, 0)
    }
}
