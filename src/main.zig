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
    _ = buffer;
}

var boot_info: BootInfo = undefined;

// linking entry point symbol
comptime { _ = @import("boot/limine/entry.zig"); }

pub fn main(_boot_info: BootInfo) noreturn {
    boot_info = _boot_info;
    //system.assembly.flags.clear_interrupt();

    // Setupping system-dependant resources
    system.init() catch @panic("System could not be initialized!");

    // Printing hello world
    debug.print("\nHello, World from {s}!\n", .{ @tagName(system.arch) });
 
    // // Testing general purpose alocator
    // const DebugAllocator = std.heap.DebugAllocator(.{
    //     .thread_safe = false
    // });
    
    // var gpalloc: DebugAllocator = .init;
    // const allocator = gpalloc.allocator();

    // const heap = allocator.alloc(usize, 10) catch unreachable;
    // const random = std.crypto.random;

    // for (0..10) |i| {
    //     heap[i] = random.int(usize);
    // }
    
    // for (0..10) |i| {
    //     debug.print("Value in heap[{}] is {}", .{i, heap[i]});
    // }

    // _ = allocator.resize(heap, 2048);
    // debug.dumpHex(std.mem.sliceAsBytes(heap));

    // allocator.free(heap);

    var slice: []u8 = undefined;
    slice.len = 4096;
    slice.ptr = @as([*]u8, @ptrFromInt(0x10000));

    @memset(slice, 0xBB);

    debug.dumpHex(slice);

    while (true) {}
    unreachable;
}

pub inline fn get_boot_info() BootInfo {
    return boot_info;
}

pub fn panic(msg: []const u8, stack_trace: ?*std.builtin.StackTrace, return_address: ?usize) noreturn {
    _ = return_address;

    debug.print("!!! KERNEL PANIC !!!\n", .{});
    debug.print("Error: {s}\n", .{msg});

    if (stack_trace) |st| {
        debug.dumpStackTrace(st.*);
    }

    while (true) {}
}
