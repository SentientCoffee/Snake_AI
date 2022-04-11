package input

when ODIN_DEBUG {
    import log "../logging"
}

import "vendor:glfw"

Input :: struct {
    keys_pressed   : #sparse [Key_Code]int,
    mouse_button   : [Mouse_Button]bool,
    mouse_position : [2]f64,
    mouse_scroll   : [2]f64,
}


g_input : Input

poll_for_events :: proc() {
    glfw.PollEvents()
}

key_press_callback :: proc "c" (handle : glfw.WindowHandle, key, scan_code, action, mods : i32) {
    if !is_valid_enum(Key_Code, key) { return }

    key_code := Key_Code(key)
    switch action {
        case glfw.PRESS:   g_input.keys_pressed[key_code]  = 1
        case glfw.REPEAT:  g_input.keys_pressed[key_code] += 1
        case glfw.RELEASE: g_input.keys_pressed[key_code]  = 0
        case:
    }

    when ODIN_DEBUG {
        if pressed := g_input.keys_pressed[key_code]; pressed > 0 {
            log.trace_c("Input", "Key pressed: {} ({})", key_code, pressed)
        }
    }
}

mouse_button_callback :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
    if !is_valid_enum(Mouse_Button, button) { return }

    mouse_button := Mouse_Button(button)
    switch action {
        case glfw.PRESS:   g_input.mouse_button[mouse_button] = true
        case glfw.RELEASE: g_input.mouse_button[mouse_button] = false
        case:
    }

    when ODIN_DEBUG {
        if pressed := g_input.mouse_button[mouse_button]; pressed {
            log.trace_c("Input", "Mouse button pressed: {}", mouse_button)
        }
    }
}

mouse_position_callback :: proc "c" (window: glfw.WindowHandle, x_position, y_position: f64) {
    when ODIN_DEBUG {
        if g_input.mouse_position != { x_position, y_position } {
            log.trace_c("Input", "Mouse moved: {{ {}, {} }}", x_position, y_position)
        }
    }
    g_input.mouse_position = { x_position, y_position }
}

mouse_scroll_callback :: proc "c" (handle : glfw.WindowHandle, x_offset, y_offset : f64) {
    when ODIN_DEBUG {
        if g_input.mouse_scroll != { x_offset, y_offset } {
            log.trace_c("Input", "Mouse scrolled: {{ {}, {} }}", x_offset, y_offset)
        }
    }
    g_input.mouse_scroll = { x_offset, y_offset }
}

// -----------------------------------------------------------------------------------

@(private="file")
is_valid_enum :: proc "c" ($Enum_Type : typeid, value : i32) -> bool {
    for e in Enum_Type {
        if auto_cast value == e { return true }
    }
    return false
}
