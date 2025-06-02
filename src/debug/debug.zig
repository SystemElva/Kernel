const root = @import("root");
const std = @import("std");

pub const serial = root.system.serial;
const tty_config: std.io.tty.Config = .no_color;

pub inline fn print(fmt: []const u8, args: anytype) void {
    serial.writer().print(fmt, args) catch unreachable;
}

pub fn dumpStackTrace(stackTrace: std.builtin.StackTrace) void {
    print("TODO: stack trace", .{});
    _ = stackTrace;
}


pub fn dumpHex(bytes: []const u8) void {
    dumpHexInternal(bytes, tty_config, serial.writer()) catch {};
}
pub fn dumpHexFailable(bytes: []const u8) void {
    try dumpHexInternal(bytes, tty_config, serial.writer());
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
