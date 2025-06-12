const root = @import("root");
const std = @import("std");
const builtin = @import("builtin");

pub const serial = root.system.serial;
const tty_config: std.io.tty.Config = .no_color;

const stdout = 0;
const stderr = 1;

pub const StackTrace = struct {

};

pub inline fn print(fmt: []const u8, args: anytype) void {
    serial.writer(stdout).print(fmt, args) catch |e| std.debug.panic("print error: {s}", .{@errorName(e)});
}
pub inline fn err(fmt: []const u8, args: anytype) void {
    serial.writer(stderr).print(fmt, args) catch |e| std.debug.panic("print error: {s}", .{@errorName(e)});
}


pub fn dumpStackTrace(ret_address: usize) void {

    if (builtin.strip_debug_info) {
        print("Unable to dump stack trace: debug info stripped\n", .{});
        return;
    }

    const writer = serial.writer(stderr);

    // I hate my life
    switch (root.system.arch) {
        .x86_64 => @import("../system/x86_64/debug/stackTrace.zig").dumpStackTrace(ret_address, writer),
        else => unreachable
    }
}


pub fn dumpHex(bytes: []const u8) void {
    dumpHexInternal(bytes, tty_config, serial.writer(stdout)) catch {};
}
pub fn dumpHexFailable(bytes: []const u8) void {
    try dumpHexInternal(bytes, tty_config, serial.writer(stdout));
}

// Reimplementation of zig's `std.debug.dumpHexInternal`
fn dumpHexInternal(bytes: []const u8, ttyconf: std.io.tty.Config, writer: anytype) !void {
    var chunks = std.mem.window(u8, bytes, 16, 16);
    while (chunks.next()) |window| {
        const address = (@intFromPtr(bytes.ptr) + 0x10 * (std.math.divCeil(usize, chunks.index orelse bytes.len, 16) catch unreachable)) - 0x10;
        
        try ttyconf.setColor(writer, .dim);
        try writer.print("{x:0>[1]}  ", .{ address, @sizeOf(usize) * 2 });
        try ttyconf.setColor(writer, .reset);

        for (window, 0..) |byte, index| {
            try writer.print("{X:0>2} ", .{byte});
            if (index == 7) try writer.writeByte(' ');
        }
        try writer.writeByte(' ');
        if (window.len < 16) {
            var missing_columns = (16 - window.len) * 3;
            if (window.len < 8) missing_columns += 1;
            try writer.writeByteNTimes(' ', missing_columns);
        }

        for (window) |byte| {
            if (std.ascii.isPrint(byte)) try writer.writeByte(byte)
            else { // Not printable char

                if (ttyconf == .windows_api) {
                    try writer.writeByte('.');
                    continue;
                }

                switch (byte) {
                    '\n' => try writer.writeAll("␊"),
                    '\r' => try writer.writeAll("␍"),
                    '\t' => try writer.writeAll("␉"),
                    else => try writer.writeByte('.'),
                }
            }
        }
        
        try writer.writeByte('\n');
    }
}
