const std = @import("std");
const BootInfo = boot.BootInfo;

// root public
pub const boot = @import("boot/boot.zig");
pub const system = @import("system/system.zig");

var boot_info: BootInfo = undefined;

// linking entry point symbol
comptime { _ = @import("boot/limine/entry.zig"); }

pub fn main(_boot_info: BootInfo) noreturn {
    boot_info = _boot_info;
    system.flags.clear_interrupt();

    // Setupping system-dependant resources
    system.init() catch @panic("System could not be initialized!");

    // Setupping IO and debug
    system.serial.init() catch @panic("Serial could not be initialized!");

    // Printing hello world
    _ = system.serial.writer().print("\nHello, World from {s}!\n", .{ @tagName(system.arch) }) catch unreachable;
 
    while (true) {}
    unreachable;
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
