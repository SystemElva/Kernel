const std = @import("std");

pub const Guid = packed struct {
    data1: u32,
    data2: u16,
    data3: u16,
    data4: [8]u8,

    pub fn fromInt(value: u128) Guid {
        return @bitCast(value);
    }

    pub fn fromSlice(bytes: []const u8) !Guid {
        if (bytes.len != 16) return error.InvalidLength;
        return std.mem.bytesToValue(Guid, bytes);
    }

    // format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    pub fn fromString(str: []const u8) !Guid {
        var buf: [16]u8 = undefined;
        const len = str.len;
        if (len != 36) return error.InvalidFormat;

        var i: usize = 0;
        var j: usize = 0;
        while (i < len) {
            if (str[i] == '-') {
                i += 1;
                continue;
            }
            if (i + 1 >= len or j >= 16) return error.InvalidFormat;
            const b = try std.fmt.parseInt(u8, str[i..i+2], 16);
            buf[j] = b;
            i += 2;
            j += 1;
        }
        return fromSlice(&buf);
    }

    /// format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    pub fn format(s: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, fmt: anytype) !void {
        const bytes: *const [16]u8 = @ptrCast(&s);

        try fmt.print("{08x}-{04x}-{04x}-{02x}{02x}-{02x}{02x}{02x}{02x}{02x}{02x}",
            .{
                s.data1,
                s.data2,
                s.data3,
                bytes[8], bytes[9],
                bytes[10], bytes[11],
                bytes[12], bytes[13],
                bytes[14], bytes[15],
            }
        );
    }

    pub fn isZero(self: @This()) bool {
        return @as(u128, @bitCast(self)) == 0;
    }
    pub fn eql(a: @This(), b: @This()) bool {
        return @as(u128, @bitCast(a)) == @as(u128, @bitCast(b));
    }
};