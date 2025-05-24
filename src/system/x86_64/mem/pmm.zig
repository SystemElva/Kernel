const root = @import("root");
const std = @import("std");
const assembly = root.system.assembly;

const debug = root.system.serial.writer();


var total_memory_bytes: u128 = 0;

const units = [_]struct { name: []const u8, size: u128 } {
    .{ .name = "TiB", .size = 1024 * 1024 * 1024 * 1024 },
    .{ .name = "GiB", .size = 1024 * 1024 * 1024 },
    .{ .name = "MiB", .size = 1024 * 1024 },
    .{ .name = "KiB", .size = 1024 },
    .{ .name = "B",   .size = 1 },
};

pub fn setup() void {
    
    debug.print("allocating {} bytes...\n", .{@sizeOf(?Block) * 100}) catch unreachable;
    const mem_buffer = assembly.salloc(@sizeOf(?Block) * 100);
    defer assembly.sfree(mem_buffer);

    var blocks = @as([*]?Block, @ptrCast(@alignCast(mem_buffer.ptr)))[0 .. 100];
    var next_free_block: usize = 0;
    @memset(blocks, null);

    blocks[0] = .{
        .start = 0x100000,
        .length = std.math.maxInt(usize),

        .status = .free,

        .previous = null,
        .next = null
    };
    next_free_block = 1;
    const mmap = root.get_boot_info().memory_map;

    for (mmap) |i| {

        debug.print("b: {X: >16} e: {X: >16} t: {s}\n", .{ i.base, i.base + i.size, @tagName(i.type) }) catch unreachable;

        if (i.type == .usable) {
            total_memory_bytes += i.size;
        }

    }

    var i: usize = 0;
    while (true) : (i += 1) if (total_memory_bytes >= units[i].size) break;

    const size_float: f64 = @floatFromInt(total_memory_bytes);
    const unit_float: f64 = @floatFromInt(units[i].size);

    debug.print("Total memory available: {d:.2} {s}\n", .{size_float / unit_float, units[i].name}) catch unreachable;

}

const Block = struct {
    start: usize,
    length: usize,

    status: BlockStatus,

    previous: ?*Block,
    next: ?*Block
};

const BlockStatus = enum {
    free,
    kernel,
    kernel_heap,

    program_code,
    program_data,
    program_misc,
};
