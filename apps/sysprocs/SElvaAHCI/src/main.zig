const std = @import("std");
const root = @import("root");
const modules = root.modules;
const sys = root.system;
const debug = root.debug;

const allocator = root.mem.heap.kernel_allocator;

pub fn _start(args: ?*anyopaque) callconv(.c) noreturn {

    _ = args;

    debug.print("Hello, SElvaAHCI!", .{});

    // This routine should register the SElvaAHCI driver
    // and wait til the end of the routine

    modules.register_module(
        "SElvaAHCI",
        "0.1.0",
        "System Elva Team",
        "MPL-2.0",

        init,
        deinit,

        .{ .pci_devices = true },
    );

    // TODO sleep function
    while (true) {}
    unreachable;
}

fn init() callconv(.c) bool {

}
fn deinit() callconv(.c) void {

}
