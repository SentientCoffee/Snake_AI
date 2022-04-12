package application

import "../input"
import log "../logging"
import "../renderer"

import "core:strings"

import "vendor:glfw"
import gl "vendor:OpenGL"

@(private="file") gl_major_version :: 4
@(private="file") gl_minor_version :: 5

@(private="file") glfw_initialized := false

// -----------------------------------------------------------------------------------

Window :: struct {
    width, height : int,
    title         : string,
    closed        : bool,
    handle        : glfw.WindowHandle,
}

// -----------------------------------------------------------------------------------

create_window :: proc(width, height: int, title: string) -> (window: ^Window) {
    set_window_callbacks :: proc(handle : glfw.WindowHandle) {
        glfw.SetWindowCloseCallback(handle, window_close_callback)
        glfw.SetWindowSizeCallback (handle, window_size_callback )
    }

    window_close_callback :: proc "c" (handle : glfw.WindowHandle) {
        window := cast(^Window) glfw.GetWindowUserPointer(handle)
        window.closed = true
        glfw.SetWindowShouldClose(handle, true)
    }

    window_size_callback :: proc "c" (handle : glfw.WindowHandle, width, height : i32) {
        window := cast(^Window) glfw.GetWindowUserPointer(handle)
        window.width  = cast(int) width
        window.height = cast(int) height
        renderer.set_viewport(0, 0, width, height)
    }

    window = nil

    log.info("Window", "Creating window \"{}\" ({} x {})", title, width, height)

    if !glfw_initialized {
        glfw_ok := bool(glfw.Init())
        log.assert(glfw_ok, "GLFW", "Failed to initialize!")
        glfw.SetErrorCallback(log.glfw_error_callback)
        glfw_initialized = true
    }

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, gl_major_version)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, gl_minor_version)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    handle := glfw.CreateWindow(cast(i32) width, cast(i32) height, strings.clone_to_cstring(title), nil, nil)
    log.assert(handle != nil, "GLFW", "Failed to load the window!")

    glfw.MakeContextCurrent(handle)
    set_window_callbacks(handle)
    input.init(handle)

    gl.load_up_to(gl_major_version, gl_minor_version, glfw.gl_set_proc_address)

    when ODIN_DEBUG {
        gl.Enable(gl.DEBUG_OUTPUT)
        gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS)
        gl.DebugMessageCallback(log.gl_error_callback, nil);
        gl.DebugMessageControl(gl.DONT_CARE, gl.DONT_CARE, gl.DONT_CARE, 0, nil, gl.TRUE);
    }

    _sep :: "\n------------------------------------------------------------------------------------"
    log.info("OpenGL", "    OpenGL version: {}",   gl.GetString(gl.VERSION))
    log.info("OpenGL", "    GLSL version:   {}",   gl.GetString(gl.SHADING_LANGUAGE_VERSION))
    log.info("OpenGL", "    Vendor:         {}",   gl.GetString(gl.VENDOR))
    log.info("OpenGL", "    Renderer:       {}{}", gl.GetString(gl.RENDERER), _sep)

    window = new(Window);
    window^ = Window{ width, height, title, false, handle }
    glfw.SetWindowUserPointer(handle, window)
    return
}

destroy_window :: proc(using w : ^Window) {
    glfw.DestroyWindow(handle)
    glfw.Terminate()
    free(w)
}

window_swap_buffers :: proc(using w : ^Window) {
    glfw.SwapBuffers(handle)
}
