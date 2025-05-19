pub const boot = @import("boot/boot.zig");
pub const system = @import("system/system.zig");

var boot_info: BootInfo = undefined;

// linking entry point symbol
comptime { _ = @import("boot/limine/entry.zig"); }

pub fn main(_boot_info: BootInfo) !void {
    boot_info = _boot_info;

    // Setupping system-dependant resources
    try system.init();

    // Setupping IO and debug
    try system.serial.init();

    // Printing hello world
    _ = try system.serial.writer().print("Hello, World from {s}!", .{ @tagName(system.arch) });

}

pub inline fn get_boot_info() BootInfo {
    return boot_info;
}

pub fn panic(msg: []const u8, stack_trace: ?*std.builtin.StackTrace, return_address: ?usize) noreturn {
    _ = return_address;
    _ = stack_trace;
    _ = msg;

    while (true) {}
}


const std = @import("std");
const BootInfo = boot.BootInfo;
