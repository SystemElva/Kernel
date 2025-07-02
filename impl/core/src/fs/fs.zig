const std = @import("std");
const root = @import("root");

pub const FsNode = @import("fs_node.zig").FsNode;
pub const default_nodes = @import("default_nodes.zig");

const kernel_allocator = root.mem.heap.kernel_buddy_allocator;

var arena: std.heap.ArenaAllocator = undefined;
var allocator: std.mem.Allocator = undefined;

var fs_root: default_nodes.VirtualDirectory = undefined;


pub fn init() void {

    arena = .init(allocator);
    allocator = arena.allocator();

    root.debug.print("aaaaaaaa\n", .{});

    // Creating root node
    fs_root = default_nodes.VirtualDirectory.init("root", allocator);
    fs_root.set_context();

}


pub fn lsdir() void {

    // todo iterate nodes bruh

}
