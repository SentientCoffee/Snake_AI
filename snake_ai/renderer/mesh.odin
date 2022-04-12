package renderer

when ODIN_DEBUG {
    import log "../logging"
}
import "../math"

import gl "vendor:OpenGL"

Vertex :: struct {
    position  : math.Vector3,
    normal    : math.Vector3,
    uv_coords : math.Vector2,
}

Layout_Element :: struct {
    name         : string,
    data_type    : Shader_Data_Type,
    size, offset : uint,
    components   : uint,
    normalized   : bool,
}

Vertex_Buffer_Layout :: struct {
    elements : []Layout_Element,
    stride   : uint,
}

Buffer :: struct {
    id : u32,
    type : union {
        ^Vertex_Buffer,
        ^Index_Buffer,
    },
}

Vertex_Buffer :: struct {
    using buffer : Buffer,
    vertex_count : int,
    layout       : Vertex_Buffer_Layout,
}

Index_Buffer :: struct {
    using buffer : Buffer,
    index_count  : int,
}

Mesh :: struct {
    rendering_id  : u32,
    vertex_buffer : ^Vertex_Buffer,
    index_buffer  : ^Index_Buffer,
}

// -----------------------------------------------------------------------------------

create_layout_element :: proc(name : string, type : Shader_Data_Type, normalized := false) -> (element : Layout_Element) {
    element.name = name
    element.data_type = type
    element.normalized = normalized

    switch type {
        case .Bool:  fallthrough
        case .Int:   fallthrough
        case .Float: element.components = 1

        case .Int2:   fallthrough
        case .Float2: element.components = 2

        case .Int3:   fallthrough
        case .Float3: element.components = 3

        case .Int4:   fallthrough
        case .Float4: element.components = 4

        case .Mat3: element.components = 3 * 3
        case .Mat4: element.components = 4 * 4

        case: element.components = 0;
    }

    switch type {
        case .Bool: fallthrough
        case .Int:  fallthrough
        case .Int2: fallthrough
        case .Int3: fallthrough
        case .Int4: element.size = element.components * size_of(i32);

        case .Float:  fallthrough
        case .Float2: fallthrough
        case .Float3: fallthrough
        case .Float4: fallthrough
        case .Mat3:   fallthrough
        case .Mat4:   element.size = element.components * size_of(f32);

        case: element.size = 0;
    }

    return
}

create_vertex_buffer_layout :: proc(elements : []Layout_Element) -> Vertex_Buffer_Layout {
    elements := elements
    offset, stride : uint = 0, 0

    for elem in &elements {
        elem.offset = offset;
        offset += elem.size;
        stride += elem.size;
    }

    return Vertex_Buffer_Layout{ elements, stride }
}

new_vertex_buffer :: proc(vertices : []Vertex, layout : Vertex_Buffer_Layout, usage := Buffer_Usage.Static_Draw) -> (buffer : ^Vertex_Buffer) {
    id : u32
    gl.CreateBuffers(1, &id)
    gl.NamedBufferData(id, len(vertices) * size_of(Vertex), raw_data(vertices), cast(u32) usage)

    buffer  = new(Vertex_Buffer)
    buffer^ = Vertex_Buffer{ { id, buffer }, len(vertices), layout }
    return
}

new_index_buffer :: proc(indices : []u32, usage := Buffer_Usage.Static_Draw) -> (buffer : ^Index_Buffer) {
    id : u32
    gl.CreateBuffers(1, &id)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, id)
    defer gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)

    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(u32), raw_data(indices), cast(u32) usage)

    buffer  = new(Index_Buffer)
    buffer^ = Index_Buffer{ { id, buffer }, len(indices) }
    return
}

free_buffer :: proc(buffer : ^Buffer) {
    gl.DeleteBuffers(1, &buffer.id)
    free(buffer)
}

new_mesh :: proc(vertices : []Vertex, indices : []u32) -> (mesh : ^Mesh) {
    id : u32
    gl.CreateVertexArrays(1, &id)

    layout_elements := []Layout_Element{
        create_layout_element("in_position", .Float3),
        create_layout_element("in_normal",   .Float3),
        create_layout_element("in_uv",       .Float2),
    }

    layout := create_vertex_buffer_layout(layout_elements)
    vbo := new_vertex_buffer(vertices, layout)
    ibo := new_index_buffer(indices)
    {
        gl.BindVertexArray(id)
        defer gl.BindVertexArray(0)

        gl.BindBuffer(gl.ARRAY_BUFFER, vbo.id)
        for elem, i in layout.elements {
            ogl_type : u32
            switch elem.data_type {
                case .Bool: ogl_type = gl.BOOL

                case .Int:  fallthrough
                case .Int2: fallthrough
                case .Int3: fallthrough
                case .Int4: ogl_type = gl.INT

                case .Float:  fallthrough
                case .Float2: fallthrough
                case .Float3: fallthrough
                case .Float4: fallthrough
                case .Mat3:   fallthrough
                case .Mat4:   ogl_type = gl.FLOAT

                case: ogl_type = 0;
            }

            gl.EnableVertexAttribArray(cast(u32) i);
            gl.VertexAttribPointer(cast(u32) i, cast(i32) elem.components, ogl_type, elem.normalized, cast(i32) vbo.layout.stride, cast(uintptr) elem.offset)
        }

        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo.id)
    }


    mesh  = new(Mesh)
    mesh^ = Mesh{ id, vbo, ibo }
    return
}

free_mesh :: proc(mesh : ^Mesh) {
    gl.DeleteVertexArrays(1, &mesh.rendering_id)

    free_buffer(mesh.index_buffer)
    free_buffer(mesh.vertex_buffer)
    free(mesh)
}

set_mesh_for_rendering :: proc(using mesh : ^Mesh) {
    if mesh != nil {
        when ODIN_DEBUG {
            log.assert(rendering_id != 0, "Mesh", "Invalid vertex array, unable to bind")
        }
        gl.BindVertexArray(rendering_id)
    }
    else {
        gl.BindVertexArray(0)
    }
}
