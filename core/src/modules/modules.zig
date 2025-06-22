const std = @import("std");
const root = @import("root");
const system = root.system;
const debug = root.debug;
const allocator = root.mem.heap.kernel_allocator;

const ModulesList = std.ArrayList(Module);
var modules_list: ModulesList = undefined;

pub fn init() void {
    debug.err("Initializing modules service...\n", .{});

    modules_list = ModulesList.init(allocator);
}

pub fn lsmodules() void {
    debug.print("Listing active modules:\n", .{});
    for (modules_list.items) |i| {
        debug.print("{s: >15} {s: >7} by {s} ({s} liscence)", .{ i.name, i.version, i.author, i.license });
    }
}


pub export fn register_module(
    name: [*:0]const u8,
    version: [*:0]const u8,
    author: [*:0]const u8,
    license: [*:0]const u8,

    init_func:   *const fn () callconv(.c) bool,
    deinit_func: *const fn () callconv(.c) void,

    behavior: ModulePermissions,
) bool {

    const name_slice = std.mem.sliceTo(name, 0);
    const version_slice = std.mem.sliceTo(version, 0);
    const author_slice = std.mem.sliceTo(author, 0);
    const license_slice = std.mem.sliceTo(license, 0);

    const module: Module = .{
        .name = name_slice,
        .version = version_slice,
        .author = author_slice,
        .license = license_slice,
        .guid = root.utils.Guid.new(),

        .init = init_func,
        .deinit = deinit_func,

        .behavior = behavior,
    };

    // Check if the module is already registered
    for (modules_list.items) |existing_module| {
        if (std.mem.eql(u8, existing_module.name, module.name)) {
            debug.err("Module '{s}' ver. {s} is already registered.\n", .{module.name, module.version});
            return false;
        }
    }

    // Add the module to the list
    modules_list.append(module) catch {
        debug.err("Failed to register module '{s}'.\n", .{module.name});
        return false;
    };

    debug.print("Module '{s}' registered successfully.\n", .{module.name});
    return true;

}

pub const Module = struct {
    name: []const u8,
    version: []const u8,
    author: []const u8,
    license: []const u8,
    guid: root.utils.Guid,

    init:   *const fn () callconv(.c) bool,
    deinit: *const fn () callconv(.c) void,

    behavior: ModulePermissions,
};

pub const ModulePermissions = packed struct(u64) {
    pci_devices: bool = false,
    acpi_devices: bool = false,
    usb_devices: bool = false,
    _: u61 = 0
};
