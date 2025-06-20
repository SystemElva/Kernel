const std = @import("std");
const gdt = @import("globalDescriptorTable.zig");
const idt = @import("interruptDescriptorTable.zig");

cr2: u64,
es: u64,
ds: u64,

r15: u64,
r14: u64,
r13: u64,
r12: u64,
r11: u64,
r10: u64,
r9: u64,
r8: u64,
rdi: u64,
rsi: u64,
rbp: u64,
rdx: u64,
rcx: u64,
rbx: u64,
rax: u64,
intnum: u64,

// Fetched by the cpu
error_code: u64,
rip: u64,
cs: u64,
eflags: Flags,
rsp: u64,
ss: u64,

const Flags = packed struct(u64) {
    carry: bool,     _rsvd_0: u1,
    parity: bool,    _rsvd_1: u1,
    auxiliary: bool, _rsvd_2: u1,
    zero: bool,
    sign: bool,      _rsvd_3: u5,
    overflow: bool,

    _: u50
};

pub fn format(self: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, fmt: anytype) !void {

    // General purpose registers
    try fmt.print("RAX={x:0>16} RBX={x:0>16} RCX={x:0>16} RDX={x:0>16}\n", .{ self.rax, self.rbx, self.rcx, self.rdx });
    try fmt.print("RSI={x:0>16} RDI={x:0>16} RBP={x:0>16} RSP={x:0>16}\n", .{ self.rsi, self.rdi, self.rbp, self.rsp });
    try fmt.print("R8 ={x:0>16} R9 ={x:0>16} R10={x:0>16} R11={x:0>16}\n", .{ self.r8, self.r9, self.r10, self.r11 });
    try fmt.print("R12={x:0>16} R13={x:0>16} R14={x:0>16} R15={x:0>16}\n", .{ self.r12, self.r13, self.r14, self.r15 });

    // rip, flags, privilege level
    try fmt.print("rip={x:0>16} ", .{ self.rip });
    try fmt.print("FLG={X:8} [{c}{c}{c}{c}{c}{c}] CPL={} INT={X:0>8} ERR={X:0>16}\n", .{
        @as(u64, @bitCast(self.eflags)) & 0xffffffff,

        @as(u8, if (self.eflags.overflow) 'O' else '-'),   // OF: Overflow Flag
        @as(u8, if (self.eflags.sign) 'S' else '-'),       // SF: Sign Flag
        @as(u8, if (self.eflags.zero) 'Z' else '-'),       // ZF: Zero Flag
        @as(u8, if (self.eflags.auxiliary) 'A' else '-'),  // AF: Auxiliary Carry
        @as(u8, if (self.eflags.parity) 'P' else '-'),     // PF: Parity Flag
        @as(u8, if (self.eflags.carry) 'C' else '-'),      // CF: Carry Flag

        self.cs & 0b11,
        self.intnum,
        self.error_code
    });

    // Segment selectors
    try write_segment(fmt, "ES", self.es >> 7);
    try write_segment(fmt, "CS", self.cs >> 7);
    try write_segment(fmt, "SS", self.ss >> 7);
    try write_segment(fmt, "DS", self.ds >> 7);
    
    try fmt.print("GDT=     {X:0>16} {X:0>8}\n", .{ gdt.get_ptr().base, gdt.get_ptr().limit });
    try fmt.print("ITD=     {X:0>16} {X:0>8}\n", .{ idt.get_ptr().base, idt.get_ptr().limit });

    try fmt.print("CR2={x:0>16}\n", .{ self.cr2 });

}

fn write_segment(writer: anytype, reg: *const [2:0]u8, index: usize) !void {

    const entry = gdt.tables[index];
    try writer.print("{s}={X:0>4} {X:0>16} {X:0>8} {X:0>8} DPL={} {s: <8} [{c}{c}{c}]\n", .{
        reg, index,
        (@as(u32, @intCast(entry.base_high)) << 16) | (@as(u32, @intCast(entry.base_middle)) << 8) | @as(u32, @intCast(entry.base_low)),
        (@as(u32, @intCast(entry.limit_high)) << 16) | @as(u32, @intCast(entry.limit_low)),
        (@as(u32, @intCast(@as(u8, @bitCast(entry.access)))) << 24)
            | (@as(u32, @intCast(@as(u4, @bitCast(entry.flags)))) << 20)
            | (@as(u32, @intCast(@as(u4, @truncate(entry.limit_high)))) << 16)
            | (@as(u32, @intCast(@as(u4, @truncate(entry.base_high)))) << 8),
        entry.access.privilege,
        ststr(@intFromEnum(entry.access.segment_type), @truncate(@as(u8, @bitCast(entry.access)) & 0x0f)),
        @as(u8, if (entry.access.executable) 'X' else '-'),
        @as(u8, if (entry.access.readable_writeable) 'W' else 'R'),
        @as(u8, if (entry.access.acessed) 'A' else '-'),
    });

}

/// Descriptor Type String
fn ststr(s: u1, typ: u4) []const u8 {
    if (s == 1) return switch (typ) {
        0x0 => "DataRO",
        0x1 => "DROAcc",
        0x2 => "DataRW",
        0x3 => "DRWAcc",
        0x4 => "DRODown",
        0x5 => "DRDAcc",
        0x6 => "DRWDown",
        0x7 => "DWDAcc",
        0x8 => "CodeX",
        0x9 => "CXAcc",
        0xA => "CodeXR",
        0xB => "CXRAcc",
        0xC => "CXConf",
        0xD => "CXCAcc",
        0xE => "CXRCnf",
        0xF => "CXRAcC",
    } else return switch (typ) {
        0x1 => "TSSAv16",
        0x2 => "LDT",
        0x3 => "TSSBs16",
        0x4 => "Call16",
        0x5 => "TaskGt",
        0x6 => "Int16",
        0x7 => "Trap16",
        0x9 => "TSSAv32",
        0xB => "TSSBs32",
        0xC => "Call32",
        0xE => "Int32",
        0xF => "Trap32",
        else => "SysResv",
    };
}


