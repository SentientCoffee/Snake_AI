package logging

import gl "vendor:OpenGL"

glfw_error_callback :: proc "c" (error_code : i32, message : cstring) {
    error_c("GLFW", "({}) {}", error_code, message)
}

gl_error_callback :: proc "c" (source : u32, debug_type : u32, id : u32, severity : u32, length : i32, message : cstring, user_param : rawptr) {
    // @Note(Daniel): Ignore non-significant error/warning codes.
    if id == 131169 || id == 131185 || id == 131218 || id == 131204 { return }

    type_str : string
    switch debug_type {
        case gl.DEBUG_TYPE_ERROR:                   type_str = "ERROR"
        case gl.DEBUG_TYPE_DEPRECATED_BEHAVIOR:     type_str = "DEPRECATED BEHAVIOUR"
        case gl.DEBUG_TYPE_UNDEFINED_BEHAVIOR:      type_str = "UNDEFINED BEHAVIOUR"
        case gl.DEBUG_TYPE_PORTABILITY:             type_str = "PORTABILITY ISSUE"
        case gl.DEBUG_TYPE_PERFORMANCE:             type_str = "PERFORMANCE ISSUE"
        case gl.DEBUG_TYPE_MARKER:                  type_str = "MARKER"
        case gl.DEBUG_TYPE_PUSH_GROUP:              type_str = "PUSH GROUP"
        case gl.DEBUG_TYPE_POP_GROUP:               type_str = "POP GROUP"
        case gl.DEBUG_TYPE_OTHER:                   type_str = "OTHER"
        case:
    }

    source_str : string
    switch(source) {
        case gl.DEBUG_SOURCE_API:             source_str = "API"
        case gl.DEBUG_SOURCE_WINDOW_SYSTEM:   source_str = "Window system"
        case gl.DEBUG_SOURCE_SHADER_COMPILER: source_str = "Shader compiler"
        case gl.DEBUG_SOURCE_THIRD_PARTY:     source_str = "Third party"
        case gl.DEBUG_SOURCE_APPLICATION:     source_str = "Application"
        case gl.DEBUG_SOURCE_OTHER:           source_str = "Other"
        case:
    }

    severity_str : string
    switch(severity) {
        case gl.DEBUG_SEVERITY_HIGH:         severity_str = "High"
        case gl.DEBUG_SEVERITY_MEDIUM:       severity_str = "Medium"
        case gl.DEBUG_SEVERITY_LOW:          severity_str = "Low"
        case gl.DEBUG_SEVERITY_NOTIFICATION: severity_str = "Notification"
        case:
    }

    context = log_ctx^
    ogl :: "OpenGL"
    switch {
        case debug_type == gl.DEBUG_TYPE_ERROR: {
            error_c(        ogl, "{} (0x{:8x})",     type_str, id)
            error_c(        ogl, "    {}",           message)
            error_c(        ogl, "    SOURCE:   {}", source_str)
            assert_c(false, ogl, "    SEVERITY: {}", severity_str)
        }
        case severity == gl.DEBUG_SEVERITY_HIGH: {
            error_c(ogl, "{} (0x{:8x})",     type_str, id)
            error_c(ogl, "    {}",           message)
            error_c(ogl, "    SOURCE:   {}", source_str)
            error_c(ogl, "    SEVERITY: {}", severity_str)
        }
        case severity == gl.DEBUG_SEVERITY_MEDIUM: {
            warning_c(ogl, "{} (0x{:8x})",     type_str, id)
            warning_c(ogl, "    {}",           message)
            warning_c(ogl, "    SOURCE:   {}", source_str)
            warning_c(ogl, "    SEVERITY: {}", severity_str)
        }
        case severity == gl.DEBUG_SEVERITY_LOW: {
            info_c(ogl, "{} (0x{:8x})",     type_str, id)
            info_c(ogl, "    {}",           message)
            info_c(ogl, "    SOURCE:   {}", source_str)
            info_c(ogl, "    SEVERITY: {}", severity_str)
        }
        case: {
            debug_c(ogl, "{} (0x{:8x})",     type_str, id)
            debug_c(ogl, "    {}",           message)
            debug_c(ogl, "    SOURCE:   {}", source_str)
            debug_c(ogl, "    SEVERITY: {}", severity_str)
        }
    }
}
