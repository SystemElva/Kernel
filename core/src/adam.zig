const std = @import("std");
const root = @import("root");
const threading = root.threading;

const debug = root.debug;

// Adam is a better term for the first father of all tasks
// than root was! - Terry A. Davis

pub fn _start(args: ?*anyopaque) callconv(.c) noreturn {
    _ = args;

    debug.print("Hello, Adam!\n", .{});

    // Running the build-in core drivers

    //const system_proc = threading.procman.get_process_from_pid(0).?;
    //_ = system_proc.create_task(
    //    &@import("../SElvaAHCI/main.zig")._start,
    //     null,
    //    255
    //) catch unreachable;

    // Adam should never return as it indicates
    // that the system is alive
    while (true) { }
    unreachable;
}
