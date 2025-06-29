const std = @import("std");
const root = @import("root");
const sys = root.system;
const debug = root.debug;

const allocator = root.mem.heap.kernel_buddy_allocator;

var disk_entry_list: []?DiskEntry = undefined;

pub fn init() void {

    disk_entry_list = allocator.alloc(?DiskEntry, 16) catch unreachable;
    @memset(disk_entry_list, null);

}

pub fn append_device(
    ctx: *anyopaque,
    devtype: ?[]const u8,
    read: DiskEntry.ReadWriteHook,
    write: DiskEntry.ReadWriteHook,
    remove: DiskEntry.RemoveHook
) usize {

    const free_slot = b: {
        for (disk_entry_list, 0..) |slot, i| {
            if (slot == null) break :b i;
        }
        @panic("TODO increase disks slots array length");
    };

    const entry = &disk_entry_list[free_slot];
    entry.* = .{
        .context = ctx,
        .vtable_read = read,
        .vtable_write = write,
        .vtable_remove = remove
    };
    if (devtype != null) entry.*.?.type = devtype.?;

    return free_slot;
}

pub fn get_disk_by_idx(index: usize) ?DiskEntry {
    return disk_entry_list[index];
}

pub fn lsblk() void {
    for (disk_entry_list, 0..) |entry, i| {
        if (entry != null) {

            debug.print("{} : {s}\n",.{ i, entry.?.type });

        }
    }
}

pub const DiskEntry = struct {

    pub const ReadWriteHook = *const fn (ctx: *anyopaque, sector: usize, buffer: [*]u8, length: usize) callconv(.c) bool;
    pub const RemoveHook = *const fn (ctx: *anyopaque) callconv(.c) void;
    const default_type: []const u8 = "UNK";

    /// Pointer to the guest context
    context: *anyopaque,

    /// The readable type name of the device
    /// e.g. `flash`, `CD`, `SSD`, `HHD`, `nVME`
    type: []const u8 = default_type,

    vtable_read: ReadWriteHook,
    vtable_write: ReadWriteHook,
    vtable_remove: RemoveHook,


    /// Performs a read operation
    pub fn read(s: @This(), sector: usize, buffer: []u8) !void {
        const ok = s.vtable_read(s.context, sector, buffer.ptr, buffer.len);
        if (!ok) return error.CannotRead;
    }

};
