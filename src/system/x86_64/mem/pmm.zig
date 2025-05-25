const root = @import("root");
const std = @import("std");
const debug = root.system.serial.writer();

const units = [_]struct { name: []const u8, size: u128 } {
    .{ .name = "TiB", .size = 1024 * 1024 * 1024 * 1024 },
    .{ .name = "GiB", .size = 1024 * 1024 * 1024 },
    .{ .name = "MiB", .size = 1024 * 1024 },
    .{ .name = "KiB", .size = 1024 },
    .{ .name = "B",   .size = 1 },
};


var total_memory_bytes: u64 = 0;


pub fn setup() void {
    
    var blocks: [20]Block = undefined;
    var next_free_block: usize = 0;

    const boot_info = root.get_boot_info();
    const mmap = boot_info.memory_map;

    debug.print("pb: {X: >16}; vb: {X: >16}\n", .{ boot_info.kernel_base_physical, boot_info.kernel_base_virtual }) catch unreachable;

    for (mmap) |i| {

        if (i.type == .usable) {
            // Entry is useable, do some checks and if valid,
            // mark it as free

            // Skip first 1MiB
            // Theorically, it is possible to use a
            // tiny range of memory bellow it in SOME
            // cases but i prefer to ignore it
            if (i.base < 0x100000) continue;

            debug.print("marking {X} .. {X} as free\n", .{ i.base, i.base + i.size}) catch unreachable;

            // Marking block as free
            blocks[next_free_block] = .{
                .start = i.base / 1024,
                .length = i.size / 1024,

                .status = .free,

                .previous = null,
                .next = null
            };
            if (next_free_block >= 1) {
                blocks[next_free_block].previous = &blocks[next_free_block - 1];
                blocks[next_free_block - 1].next = &blocks[next_free_block];
            }

            next_free_block += 1;
            total_memory_bytes += i.size;
        }

    }

    debug.print("Memory blocks:\n", .{}) catch unreachable;

    var cur: ?*Block = &blocks[0];
    while (cur != null) : (cur = cur.?.next) {

        debug.print("- beg: {: >10}; end: {: >10}; prev: {s}; next: {s}\n", .{
            cur.?.start,
            cur.?.start + cur.?.length,
            if(cur.?.previous == null) "nil" else "yes",
            if(cur.?.next == null) "nil" else "yes",
        }) catch unreachable;

    }
    debug.print("\n", .{}) catch unreachable;

    var i: usize = 0;
    while (true) : (i += 1) if (total_memory_bytes >= units[i].size) break;

    const size_float: f64 = @floatFromInt(total_memory_bytes);
    const unit_float: f64 = @floatFromInt(units[i].size);

    debug.print("Total memory available: {d:.2} {s} ({} pages)\n", .{size_float / unit_float, units[i].name, total_memory_bytes / 1024}) catch unreachable;

}

const Block = struct {
    // start and length are in pages size
    start: usize,
    length: usize,

    status: BlockStatus,

    previous: ?*Block,
    next: ?*Block
};

const BlockStatus = enum {
    free,

    kernel,
    mem_page,

    program_code,
    program_data,
    program_misc,
};
