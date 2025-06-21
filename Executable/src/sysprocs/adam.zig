const std = @import("std");
const root = @import("root");

const debug = root.debug;

// Adam is a better term for the first father of all tasks
// than root was! - Terry A. Davis

pub fn _start(args: ?*anyopaque) callconv(.c) isize {

    _ = args;

    debug.print("Hello, Adam!\n", .{});

    while (true) {}
    return 0;
}
