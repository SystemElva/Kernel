// Implementation of the users and permition system

const std = @import("std");
const root = @import("root");
const debug = root.debug;

const UserList = std.ArrayList(*User);

var allocator: std.mem.Allocator = undefined;
var user_list: UserList = undefined;

/// Represents virtual or real users
pub const User = struct {
    /// The index inside the users list
    index: usize,
    /// The unique identifier of this user
    uuid: u128,
    /// The user name
    name: []const u8,
    /// The user password
    passwd: []const u8,

    /// Indicates if the user is visible by default
    is_hiden: bool,
    /// Indicates if the user is a system user
    is_system: bool,
    // Indicates if the user has administration permission
    is_admin: bool,
    /// Indicates if the user can execute while other main
    /// user is active
    is_global: bool,

    /// the UNIX timestamp of the creation of this user
    creation_timestamp: usize,
};

pub fn init() void {

    allocator = root.mem.heap.kernel_allocator();
    user_list = UserList.init(allocator);

    // Appending the virtual system users
    append_user(.{
        .user_name = "Adam",
        .user_passwd = "0000",

        .is_hiden = false,
        .is_system = true,
        .is_admin = true,
        .is_global = true
   });

}

pub fn append_user(options: struct {
    user_name: []const u8,
    user_passwd: []const u8,

    is_hiden: bool = false,
    is_system: bool = false,
    is_admin: bool = false,
    is_global: bool = false,

    creation_timestamp: ?u64 = null
}) void {
    
    var nuser = allocator.create(User) catch @panic("OOM");
    const index = user_list.items.len;

    nuser.* = .{

        .index = index,
        .uuid = 0,
        .name = options.user_name,
        .passwd = options.user_passwd,

        .is_hiden = options.is_hiden,
        .is_system = options.is_system,
        .is_admin = options.is_admin,
        .is_global = options.is_global,

        .creation_timestamp = undefined
    };

    nuser.creation_timestamp = if (options.creation_timestamp == null)
        root.system.time.timestamp() else
        options.creation_timestamp.?;

    user_list.append(nuser) catch @panic("OOM");

}

pub fn lsusers() void {
    
    debug.print("Listing users:\n", .{});

    for (user_list.items) |i| {
        debug.print("{: <2} - {s} {x} {c}{c}{c}\n", .{
            i.index,
            i.name,
            i.uuid,

            @as(u8, if (i.is_admin) 'A' else '-'),
            @as(u8, if (i.is_system) 'S' else '-'),
            @as(u8, if (i.is_global) 'G' else '-'),
        });
    }

}
