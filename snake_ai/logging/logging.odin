package logging

import "core:fmt"
import "core:intrinsics"
import "core:log"
import "core:runtime"
import "core:strings"

Level_Trace   :: Level(0)
Level_Debug   :: Level(5)
Level_Info    :: Level.Info
Level_Warning :: Level.Warning
Level_Error   :: Level.Error
Level_Fatal   :: Level.Fatal

// -----------------------------------------------------------------------------------

@(private) Logger  :: runtime.Logger
@(private) Level   :: runtime.Logger_Level
@(private) Options :: runtime.Logger_Options

@(private) default_logger_options :: Options{ .Level, .Terminal_Color }

when ODIN_DEBUG {
    @(private) debug_break :: intrinsics.debug_trap
}
else {
    @(private) debug_break :: proc() {}
}

@(private) log_ctx : ^runtime.Context

// -----------------------------------------------------------------------------------

create_console_logger :: proc(ctx : ^runtime.Context, lowest_level := Level_Debug, options := default_logger_options) {
    ctx.logger = Logger{
        data = nil,
        lowest_level = lowest_level,
        options = options,
        procedure = console_logger_proc,
    }
    log_ctx = ctx
}

trace_c :: #force_inline proc "c" (identifier : string, format_string : string, args : ..any) {
    context = log_ctx^
    trace(identifier, format_string, ..args)
}
trace :: #force_inline proc(identifier : string, format_string : string, args : ..any) {
    str := fmt.tprintf(format_string, ..args)
    log.logf(Level_Trace, "[{}]: {}\n", identifier, str)
}

debug_c :: #force_inline proc "c" (identifier : string, format_string : string, args : ..any) {
    context = log_ctx^
    debug(identifier, format_string, ..args)
}
debug :: #force_inline proc(identifier : string, format_string : string, args : ..any) {
    str := fmt.tprintf(format_string, ..args)
    log.logf(Level_Debug, "[{}]: {}\n", identifier, str)
}

info_c :: #force_inline proc "c" (identifier : string, format_string : string, args : ..any) {
    context = log_ctx^
    info(identifier, format_string, ..args)
}
info :: #force_inline proc(identifier : string, format_string : string, args : ..any) {
    str := fmt.tprintf(format_string, ..args)
    log.logf(Level_Info,"[{}]: {}\n", identifier, str)
}

warning_c :: #force_inline proc "c" (identifier : string, format_string : string, args : ..any) {
    context = log_ctx^
    warning(identifier, format_string, ..args)
}
warning :: #force_inline proc(identifier : string, format_string : string, args : ..any) {
    str := fmt.tprintf(format_string, ..args)
    log.logf(Level_Warning, "[{}]: {}\n", identifier, str)
}

error_c :: #force_inline proc "c" (identifier : string, format_string : string, args : ..any) {
    context = log_ctx^
    error(identifier, format_string, ..args)
}
error :: #force_inline proc(identifier : string, format_string : string, args : ..any) {
    str := fmt.tprintf(format_string, ..args)
    log.logf(Level_Error, "[{}] ERROR: {}\n", identifier, str)
}

assert_c :: #force_inline proc "c" (condition : bool, identifier : string, format_string : string, args : ..any) {
    context = log_ctx^
    assert(condition, identifier, format_string, ..args)
}
assert :: #force_inline proc(condition : bool, identifier : string, format_string : string, args : ..any, location := #caller_location) {
    if condition { return }

    b : strings.Builder
    strings.init_builder(&b)
    defer strings.destroy_builder(&b)

    str := fmt.tprintf(format_string, ..args)
    split := strings.split(str, "\n")

    for s in split {
        if len(s) == 0 { continue }
        for _ in 0 ..< len(identifier) + 5 { strings.write_string_builder(&b, " ") }
        strings.write_string_builder(&b, s)
        strings.write_byte(&b, '\n')
    }

    _sep :: "------------------------------------------------------------------------------------"

    log.logf(
        Level_Fatal, "{}\n[{}] Assertion failed @ {}({},{}):\n{}{}\n",
        _sep, identifier, location.file_path, location.line, location.column, strings.to_string(b), _sep,
    )
    debug_break();
}

// -----------------------------------------------------------------------------------

@(private="file")
console_logger_proc :: proc(data : rawptr, level : Level, text : string, options : Options, location := #caller_location) {
    WHITE  :: "\x1b[0m"
    CYAN   :: "\x1b[36m"
    GREEN  :: "\x1b[92m"
    YELLOW :: "\x1b[33m"
    RED    :: "\x1b[91m"

    // @Note(Daniel): Not using data parameter

    col := WHITE
    if .Level in options {
        if .Terminal_Color in options {
            switch level {
                case Level_Trace:   col = WHITE
                case Level_Debug:   col = CYAN
                case Level_Info:    col = GREEN
                case Level_Warning: col = YELLOW
                case Level_Error:   fallthrough
                case Level_Fatal:   col = RED
            }
        }
    }

    fmt.printf("{}{}{}", col, text, WHITE)
}
