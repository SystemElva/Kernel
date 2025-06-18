const std = @import("std");
const root = @import("root");

pub const options: std.Options = .{
    .page_size_min = 4096,
    .page_size_max = 4096,

    .enable_segfault_handler = false,

    .logFn = logFn,
    .cryptoRandomSeed = criptoRandomSeed
};
fn logFn(comptime message_level: std.log.Level, comptime scope: @TypeOf(.enum_literal), comptime format: []const u8, args: anytype) void {
    _ = message_level;
    _ = scope;

    root.debug.print(format, args);
}
fn criptoRandomSeed(buffer: []u8) void {
    @memset(buffer, 0xC0);
}