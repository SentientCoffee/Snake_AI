package application

import "vendor:glfw"

Time :: struct {
    time_since_startup,
    last_frame_time,
    delta_time : f64,
}

g_time : Time

update_time :: proc() {
    using g_time
    last_frame_time = time_since_startup
    time_since_startup = glfw.GetTime()
    delta_time = time_since_startup - last_frame_time
}
