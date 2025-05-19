const std = @import("std");
const root = @import("root");
const builtin = @import("builtin");

pub const arch = builtin.cpu.arch;
pub const endian = arch.endian();

pub const serial = switch (arch) {
    .aarch64 => @import("aarchx64/serial.zig"),
    .x86_64 =>  @import("x86_64/serial.zig"),
    .x86 =>     @import("x86/serial.zig"),
    else => unreachable
};


pub const init = switch (arch) {
    .aarch64 => @import("aarchx64/general.zig").init,
    .x86_64 =>  @import("x86_64/general.zig").init,
    .x86 =>     @import("x86/general.zig").init,
    else => unreachable
};


/// Endian to host
/// Forcefully converts the endianness of the integer value given if diferent of the
/// host endianness.
pub inline fn en2h(comptime T: type, x: T, comptime e: std.builtin.Endian) T {
    return if (endian == e) return x else @byteSwap(x);
}
