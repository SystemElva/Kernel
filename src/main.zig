const std = @import("std");
const BootInfo = boot.BootInfo;

/// Boot information structures
pub const boot = @import("boot/boot.zig");
/// System-dependent implementations and core subroutines
pub const system = @import("system/system.zig");
/// Memory and Memory-management related
pub const mem = @import("mem/mem.zig");
/// Tools for debugguing and simple I/O
pub const debug = @import("debug/debug.zig");
/// Simple CPU-based graphics library
pub const gl = @import("gl/gl.zig");
/// Devices management
pub const devices = @import("devices/devices.zig");
/// Users, authentication and permissions
pub const auth = @import("auth/auth.zig");
/// Processes, tasks and execution
pub const threading = @import("threading/threading.zig");

/// Field that allow zig interfaces to comunicate
/// with the kernel. Do not mind.
pub const os = @import("os/os.zig");
/// Field that allow zig interfaces to comunicate
/// with the kernel. Do not mind.
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

    // Initializing OS-specific things
    auth.init();
    system.time.init();

    debug.print("\nDumping random data to see if everything is right:\n", .{});

    debug.print("Time: {} ({})\n", .{ system.time.get_datetime(), system.time.timestamp() });
    //system.mem.vmm.lsmemblocks();
    devices.pci.lspci();
    auth.lsusers();

    debug.print("\nSetup finished. Giving control to the scheduler...\n", .{});
    system.finalize() catch @panic("System initialization could not be finalized!");

    while (true) system.assembly.flags.set_interrupt();
    unreachable;
}

/// Returns a copy of information from the
/// bootloader
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
