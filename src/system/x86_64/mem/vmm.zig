const std = @import("std");
const root = @import("root");
const paging = @import("paging.zig");
const pmm = @import("pmm.zig");
const debug = root.debug;

const Alignment = std.mem.Alignment;
const Allocator = std.mem.Allocator;

const magic: u32 = 0x626F6F42;

var kernel_allocator: KernelAlloc = undefined;

// Implementation of a buddy allocator
const KernelAlloc = struct {
    blocks_root: *Block,
    rover: *Block,

    next_addr: usize,

    const vtable: Allocator.VTable = .{
        .alloc = &alloc,
        .resize = &resize,
        .remap = &remap,
        .free = &free
    };

    fn alloc(self: *anyopaque, len: usize, alignment: Alignment, ret_addr: usize) ?[*]u8 {
        
        _ = alignment;
        _ = ret_addr;

        const aligned_len = std.mem.alignForward(usize, len, 8);
        var s: *KernelAlloc = @ptrCast(@alignCast(self));

        debug.print("allocation requested: {}; aligned: {}\n", .{len, aligned_len});

        // Finding a free block
        const free_block: *Block = b: {

            for (0..5) |_| { 

                var cur: ?*Block = s.rover;
                if (cur.?.magic != magic) @panic("Trying to iterate though an invalid allocated block"
                    ++ "(if indeed allocated, maybe it is a heap corruption!");
                var i: usize = 0;

                while (cur != null and !(i > 0 and cur == s.rover.prev)) : ({ cur = cur.?.next; i += 1; }) {
                    if (!cur.?.used and cur.?.len >= aligned_len) break :b cur.?;
                }

                s.extend_heap() catch return null;
            }
            return null;
        };

        // Slicing the block if necessary
        if (free_block.len - aligned_len - @sizeOf(Block) > 8) {

            const next: *Block = @ptrFromInt(@intFromPtr(free_block) + @sizeOf(Block) + aligned_len);
            next.len = free_block.len - aligned_len - @sizeOf(Block);
            free_block.len = aligned_len;

            next.magic = magic;
            next.prev = free_block;
            next.next = free_block.next;

            free_block.next = next;
            free_block.used = false;

            s.rover = next;
        }

        free_block.used = true;
        const buf: [*]u8 = @ptrFromInt(@intFromPtr(free_block) + @sizeOf(Block));
        @memset(buf[0..free_block.len], 0xAA);
        return buf;
    }
    fn resize(self: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool {

        _ = alignment;
        _ = ret_addr;

        const aligned_len = std.mem.alignForward(usize, new_len, 8);
        var s: *KernelAlloc = @ptrCast(@alignCast(self));

        debug.print("resize requested: {}; aligned: {}\n", .{new_len, aligned_len});

        const curr_block: *Block = @ptrFromInt(@intFromPtr(memory.ptr) - @sizeOf(Block));
        if (curr_block.magic != magic) @panic("Trying to resize an invalid allocated block"
            ++ "(if indeed allocated, maybe it is a heap corruption!");

        // If there's no next block or next block is used, cannot resize
        if (curr_block.next == null or curr_block.next.?.used) return false;
        const next_block = curr_block.next.?;

        // If there's a gap between this and the next block, cannot resize
        if (@intFromPtr(curr_block) + @sizeOf(Block) + curr_block.len == @intFromPtr(next_block)) return false;

        const block_size = curr_block.len + next_block.len + @sizeOf(Block);

        // If the current block + next block (header included) is lesser than
        // aligned_len, cannot resize
        if (block_size < aligned_len) return false;

        // If the block is big enough to be resized, do it
        const block_rest = block_size - aligned_len;
        if (block_rest > @sizeOf(Block) + 8) {

            const nblock: *Block = @ptrFromInt(@intFromPtr(curr_block) + @sizeOf(Block) + aligned_len);
            debug.print("nblock in {X}\n", .{@intFromPtr((nblock))});

            nblock.* = .{
                .len = block_rest - @sizeOf(Block),
                .magic = magic,
                .used = false,
                .prev = curr_block,
                .next = next_block.next,
            };
            curr_block.next = nblock;
            
            // Set the new empty memory as undefined
            const new_slice_start: [*]u8 = @ptrFromInt(@intFromPtr(curr_block) + curr_block.len + @sizeOf(Block));
            const new_slice_len = aligned_len - curr_block.len;
            @memset(new_slice_start[0 .. new_slice_len], 0xAA);

            // Select it as current rover if before the old one
            if (@intFromPtr(nblock) < @intFromPtr(s.rover)) s.rover = nblock;

            return true;
        }

        debug.print("nblock in {X}\n", .{@intFromPtr((next_block))});

        // Set the new empty memory as undefined
        const new_slice_start: [*]u8 = @ptrFromInt(@intFromPtr(curr_block) + curr_block.len + @sizeOf(Block));
        const new_slice_len = aligned_len - curr_block.len;
        @memset(new_slice_start[0..new_slice_len], 0xAA);

        // Merging the blocks
        curr_block.len = aligned_len;
        curr_block.next = next_block.next;

        return true;
    }
    fn remap(self: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
        _ = self;
        _ = memory;
        _ = alignment;
        _ = ret_addr;

        const aligned_len = std.mem.alignForward(usize, new_len, 8);

        debug.print("remap requested: {}; aligned: {}\n", .{new_len, aligned_len});

        return null;
    }
    fn free(self: *anyopaque, memory: []u8, alignment: Alignment, ret_addr: usize) void {
        _ = alignment;
        _ = ret_addr;

        debug.print("free requested\n", .{});

        var s: *KernelAlloc = @ptrCast(@alignCast(self));

        const curr_block: *Block = @ptrFromInt(@intFromPtr(memory.ptr) - @sizeOf(Block));
        if (curr_block.magic != magic) @panic("Trying to free an invalid allocated block"
            ++ "(if indeed allocated, maybe it is a heap corruption!");

        curr_block.used = false;
        if (curr_block.len > 64) s.rover = curr_block;
    }

    fn extend_heap(kalloc: @This()) !void {
        _ = kalloc;
    }

    pub fn lsmemblocks(s: @This()) void {
        var cur: ?*Block = s.blocks_root;
        var i: usize = 0;

        while (cur != null) : ({ cur = cur.?.next; i += 1; }) {
            const c_start = @intFromPtr(cur) + @sizeOf(Block);

            const block_bytes = std.mem.asBytes(cur.?);
            debug.print("{X: <16} :", .{@intFromPtr(cur.?)});
            for (0..29) |j| debug.print("{X:0>2} ", .{block_bytes[j]});
            for (0..29) |j| debug.print("{c}", .{ if (std.ascii.isPrint(block_bytes[j])) block_bytes[j] else '.' });
            debug.print("\n", .{});
            
            debug.print("{x: >8}, {X: >16}, {X: >16}: ", .{cur.?.magic, c_start, cur.?.len});

            const c_end = @addWithOverflow(c_start, cur.?.len);
            debug.print("{s} {X} .. {X}{s} - {s} (next in {X})", .{
                if (cur.?.magic == magic) "OK " else "BAD",
                c_start,
                c_end[0],
                if (c_end[1] == 1) "!" else " ",
                if (cur.?.used) "used" else "free",
                if (cur.?.next) |n| @intFromPtr(n) else 0
            });
            
            if (s.blocks_root == cur) debug.print(" (root)", .{});
            if (s.blocks_root.prev == cur) debug.print(" (end)", .{});
            if (s.rover == cur) debug.print(" (rover)", .{});

            debug.print("\n\n", .{});
            if (cur.?.magic != magic) break;
        }
    }
};
const Block = struct {
    len: usize,

    magic: u32,
    used: bool,

    prev: ?*Block,
    next: ?*Block,
};


pub fn init() void {
    // Allocating 2 pages to use as initial heap
    const heap =  pmm.get_multiple_pages(2, .kernel_heap);
    const heap_start = pmm.kernel_page_end * pmm.page_size;

    // Mapping it to after the kernel
    paging.map_single_page(pmm.physFromPtr(heap), heap_start, 10, pmm.atributes_ROX_privileged_fixed) catch unreachable;

    @memset(@as([*]u8, @ptrCast(@alignCast(heap)))[0 .. pmm.page_size * 2], '@');

    const block_root: *Block = @ptrCast(@alignCast(heap));
    block_root.* = .{
        .len = pmm.page_size * 2 - @sizeOf(Block),
        .magic = magic,
        .used = false,
        .prev = null,
        .next = null
    };

    kernel_allocator = .{
        .blocks_root = block_root,
        .rover = block_root,
        .next_addr = heap_start + pmm.page_size * 2,
    };
}

pub fn allocator() Allocator {
    return .{
        .ptr = @ptrCast(&kernel_allocator),
        .vtable = &KernelAlloc.vtable
    };
}
pub fn lsmemblocks() void {
    debug.print("Kernel allocator memory blocks:\n", .{});
    debug.print("--------------------------------------------------------------------\n", .{});
    kernel_allocator.lsmemblocks();
    debug.print("--------------------------------------------------------------------\n", .{});
    debug.print("\n", .{});
}

