
pub const FsNode = extern struct {

    /// The name of this node \
    /// It can be the file/directory name
    /// of some identification for the user
    name: [*:0]const u8,

    /// The readable type of this node
    type: [*:0]const u8,

    /// The type ID string of this node,
    /// used by other modules to identify what
    /// they are handling
    type_id: [*:0]const u8,

    /// Says if the node is iterable (e.g. Directories)
    /// or not (e.g. Files)
    iterable: bool,

    /// The custom context of the node
    ctx: ?*anyopaque,

    /// Hook for the node's virtual functions
    vtable: *FsNodeVtable,

    pub const FsNodeVtable = extern struct {
        append_node: *const fn (ctx: *anyopaque, node: *FsNode) callconv(.c) bool,
        get_child: *const fn (ctx: *anyopaque, index: usize) callconv(.c) ?*FsNode,
    };

    pub fn get_iterator(s: *@This()) callconv(.c) FsNodeIterator {
        return .{ .node = s };
    }
};

pub const FsNodeIterator = extern struct {
    node: *FsNode,
    index: usize = 0,

    pub fn next(s: @This()) ?*FsNode {
        s.index += 1;
    }
    pub fn reset(s: @This()) void {
        s.index = 0;
    }
};
