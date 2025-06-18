const std = @import("std");
const BootInfo = boot.BootInfo;

// root public
pub const boot = @import("boot/boot.zig");
pub const system = @import("system/system.zig");
pub const mem = @import("mem/mem.zig");
pub const debug = @import("debug/debug.zig");
pub const gl = @import("gl/gl.zig");
pub const devices = @import("devices/devices.zig");

pub const os = @import("os/os.zig");
pub const std_options = system.std_options.options;

var boot_info: BootInfo = undefined;

// linking entry point symbol
comptime { _ = @import("boot/limine/entry.zig"); }

pub fn main(_boot_info: BootInfo) noreturn {
    boot_info = _boot_info;
    system.assembly.flags.clear_interrupt();

    // Setting up graphics
    gl.init(
        boot_info.framebuffer.framebuffer,
        boot_info.framebuffer.width,
        boot_info.framebuffer.height,
        boot_info.framebuffer.pps
    );
    gl.clear();

    // Setupping system-dependant resources
    system.init() catch @panic("System could not be initialized!");
    // Setting up interrupts
    @import("interrupts.zig").install_interrupts();

    // Printing hello world
    debug.print("\nHello, World from {s}!\n", .{ @tagName(system.arch) });
 
    // Initializing devices
    devices.init() catch debug.print("Devices initialization failed!\n", .{});

    system.mem.vmm.lsmemblocks();

    devices.pci.lspci();

    debug.print("\nSetup finished. Giving control to the scheduler...\n", .{});
    system.finalize() catch @panic("System initialization could not be finalized!");

    system.assembly.flags.set_interrupt();

    while (true) {}
    unreachable;
}

pub inline fn get_boot_info() BootInfo {
    return boot_info;
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, return_address: ?usize) noreturn {

    debug.print("\n!!! KERNEL PANIC (see stderr) !!!\n", .{});
    debug.err("\n!!! KERNEL PANIC !!!\n", .{});
    debug.err("Error: {s}\n\n", .{msg});

    if (return_address) |ret| {
        debug.err("Stack Trace:\n", .{});
        debug.dumpStackTrace(ret);
    } else {
        debug.err("No Stack Trace\n", .{});
    }

    while (true) {}
}
