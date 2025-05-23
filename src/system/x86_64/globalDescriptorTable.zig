const std = @import("std");

var tables: [5]Entry = undefined;

pub const selector = .{
    .null = @as(u16, 0x00),
    .code64 = @as(u16, 0x08),
    .data64 = @as(u16, 0x10),
    .usercode64 = @as(u16, 0x18),
    .userdata64 = @as(u16, 0x20),
    .tss = @as(u16, 0x28),
};

const Pointer = extern struct { limit: u16, base: u64 align(2) };
const Entry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_middle: u8,
    access: Access,
    limit_high: u4,
    flags: Flags,
    base_high: u8,
};

const Access = packed struct(u8) {
    acessed: bool,
    readable_writeable: bool,
    direction_conforming: bool,
    executable: bool,
    segment_type: enum(u1) { system = 0, data = 1 },
    privilege: u2,
    present: bool
};
const Flags = packed struct(u4) {
    available: bool,
    long_mode: bool,
    real_mode: bool,
    page_sized: bool,
};

pub fn install() void {

    // Null entry
    set_gdt_entry(&tables[0],
        0, 0,
        @bitCast(@as(u8, 0)),
        @bitCast(@as(u4, 0))
    );

    // Kernel code
    set_gdt_entry(&tables[1],
        0, 0xFFFF,
        .{
            .acessed = false,
            .readable_writeable = true,
            .direction_conforming = false,
            .executable = true,
            .segment_type = .data,
            .privilege = 0,
            .present = true,
        },
        .{
            .available = false,
            .real_mode = false,
            .long_mode = true,
            .page_sized = true
        },
    );
    
    // Kernel data
    set_gdt_entry(&tables[2],
        0, 0xFFFF,
        .{
            .acessed = false,
            .readable_writeable = true,
            .direction_conforming = false,
            .executable = false,
            .segment_type = .data,
            .privilege = 0,
            .present = true,
        },
        .{
            .available = false,
            .real_mode = false,
            .long_mode = false,
            .page_sized = false
        },
    );

    // User code
    set_gdt_entry(&tables[3],
        0, 0xFFFF,
        .{
            .acessed = false,
            .readable_writeable = true,
            .direction_conforming = false,
            .executable = true,
            .segment_type = .data,
            .privilege = 3,
            .present = true,
        },
        .{
            .available = false,
            .real_mode = false,
            .long_mode = true,
            .page_sized = true
        },
    );
    
    // User data
    set_gdt_entry(&tables[4],
        0, 0xFFFF,
        .{
            .acessed = false,
            .readable_writeable = true,
            .direction_conforming = false,
            .executable = false,
            .segment_type = .data,
            .privilege = 3,
            .present = true,
        },
        .{
            .available = false,
            .real_mode = false,
            .long_mode = false,
            .page_sized = false
        },
    );


    load_gdt(&tables);
}

fn load_gdt(gdt: []Entry) void {
    var gdtp = Pointer{ .limit = @intCast(@sizeOf(Entry) * gdt.len - 1), .base = @intFromPtr(gdt.ptr) };

    // load gdt
    asm volatile ("lgdt (%[gdt])" : : [gdt] "r" (&gdtp), );

    // use data selectors
    asm volatile (
        \\ mov %[dsel], %%ds
        \\ mov %[dsel], %%fs
        \\ mov %[dsel], %%gs
        \\ mov %[dsel], %%es
        \\ mov %[dsel], %%ss
        : : [dsel] "rm" (selector.data64),
    );

    // use code selectors
    asm volatile (
        \\ push %[csel]
        \\ lea 1f(%%rip), %%rax
        \\ push %%rax
        \\ lretq
        \\ 1:
        : : [csel] "i" (selector.code64),
        : "rax"
    );
}
fn set_gdt_entry(gdt: *Entry, base: u32, limit: u20, access: Access, flags: Flags) void {

    gdt.base_low = @intCast(base & 0xFFFF);
    gdt.base_middle = @intCast((base >> 16) & 0xFF);
    gdt.base_high = @intCast((base >> 24) & 0xFF);

    gdt.limit_low = @intCast(limit & 0xFFFF);
    gdt.limit_high = @truncate(std.math.shr(u20, limit, 16) & 0xF);

    gdt.access = access;
    gdt.flags = flags;
}
