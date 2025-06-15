const std = @import("std");
const BootInfo = boot.BootInfo;

// root public
pub const boot = @import("boot/boot.zig");
pub const system = @import("system/system.zig");
pub const mem = @import("mem/mem.zig");
pub const debug = @import("debug/debug.zig");

pub const os = @import("os/os.zig");
pub const std_options: std.Options = .{
    .page_size_min = 4096,
    .page_size_max = 4096,

    .enable_segfault_handler = false,

    .logFn = logFn,
    .cryptoRandomSeed = criptoRandomSeed
};
fn logFn(comptime message_level: std.log.Level, comptime scope: @TypeOf(.enum_literal), comptime format: []const u8, args: anytype) void {
    _ = message_level;
    _ = scope;

    debug.print(format, args);
}
fn criptoRandomSeed(buffer: []u8) void {
    @memset(buffer, 0xC0);
}

var boot_info: BootInfo = undefined;

// linking entry point symbol
comptime { _ = @import("boot/limine/entry.zig"); }

pub fn main(_boot_info: BootInfo) noreturn {
    boot_info = _boot_info;
    system.assembly.flags.clear_interrupt();

    // Setupping system-dependant resources
    system.init() catch @panic("System could not be initialized!");

    // Printing hello world
    debug.print("\nHello, World from {s}!\n", .{ @tagName(system.arch) });
 
    // Trying to raise an interrupt
    asm volatile ("int $0x00");

    // Testing kernel allocator
    const allocator = system.mem.vmm.allocator();

    var heap = allocator.alloc(u32, 20) catch unreachable;
    var b1: []u8 = undefined;
    var b2: []u8 = undefined;
    b1.ptr = @ptrFromInt(@intFromPtr(heap.ptr) - 32); b1.len = 32;
    b2.ptr = @ptrFromInt(@intFromPtr(heap.ptr) + heap.len * @sizeOf(u32)); b2.len = 64;

    debug.print("new_heap_____________________\n", .{});
    debug.print("before:\n", .{});
    debug.dumpHex(b1);

    debug.print("data:\n", .{});
    debug.dumpHex(std.mem.sliceAsBytes(heap));

    debug.print("after:\n", .{});
    debug.dumpHex(b2);
    
    debug.print("\n", .{});

    @memset(heap, 0x74736554);
    

    debug.print("after_memset________________\n", .{});
    debug.print("before:\n", .{});
    debug.dumpHex(b1);

    debug.print("data:\n", .{});
    debug.dumpHex(std.mem.sliceAsBytes(heap));

    debug.print("after:\n", .{});
    debug.dumpHex(b2);
    
    debug.print("\n", .{});

    system.mem.vmm.lsmemblocks();

    _ = allocator.resize(heap, 200);
    heap = heap.ptr[0 .. 200];
    b2.ptr =  @ptrFromInt(@intFromPtr(heap.ptr) + heap.len * @sizeOf(u32)); b2.len = 64;

    debug.print("after_resize_______________\n", .{});
    debug.print("before:\n", .{});
    debug.dumpHex(b1);

    debug.print("data:\n", .{});
    debug.dumpHex(std.mem.sliceAsBytes(heap));

    debug.print("after:\n", .{});
    debug.dumpHex(b2);
    
    debug.print("\n", .{});

    system.mem.vmm.lsmemblocks();

    allocator.free(heap);

    system.mem.vmm.lsmemblocks();

    // Testing Stderr
    debug.err("Hello World from Stderr!", .{});

    debug.print("Execution ended. Halting...\n", .{});

    while (true) {}
    unreachable;
}

pub inline fn get_boot_info() BootInfo {
    return boot_info;
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, return_address: ?usize) noreturn {
    debug.print("\n!!! KERNEL PANIC !!!\n", .{});
    debug.print("Error: {s}\n\n", .{msg});

    if (return_address) |ret| {
        debug.print("Stack Trace:\n", .{});
        debug.dumpStackTrace(ret);
    } else {
        debug.print("No Stack Trace\n", .{});
    }

    while (true) {}
}
