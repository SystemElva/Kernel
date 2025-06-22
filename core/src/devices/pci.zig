const std = @import("std");
const root = @import("root");
const sys = root.system;
const allocator = root.mem.heap.kernel_allocator;

const debug = root.debug;

pub const internal = switch (sys.arch) {
    //.x86 => ,
    .x86_64 => @import("x86_64/pci/pci.zig"),
    //.aarch64 => ,
    else => unreachable
};

const Addr = internal.Addr;
pub const DeviceList = std.ArrayList(PciDevice);

var devList: DeviceList = undefined;

pub const PciDevice = struct {

    const default_string = "unknown";

    addr: Addr,

    type_str: []const u8 = default_string,
    vendor_str: []const u8 = default_string,
    name_str: []const u8 = default_string,

    pub inline fn get_bus(s: @This()) u8 { return s.addr.bus; }
    pub inline fn get_device(s: @This()) u5 { return s.addr.device; }
    pub inline fn get_function(s: @This()) u3 { return s.addr.function; }
};

pub fn init() void {
    // Initializing device list
    devList = DeviceList.init(allocator);
}

pub fn list_pci_devices() !void {
    devList.clearAndFree();

    try internal.list_devices(&devList);
}


pub fn lspci() void {

    debug.print("Listing PCI devices:\n", .{});
    for (devList.items) |i| {
        debug.print(
            "{X:0>2}:{X:0>2}.{X:0>1} [{X:0>2}:{X:0>2}] {s}: [{X:0>4}] {s} - [{X:0>4}] {s}\n",
            .{

            i.get_bus(),
            i.get_device(),
            i.get_function(),

            i.addr.base_class().read(),
            i.addr.sub_class().read(),
            i.type_str,
            i.addr.vendor_id().read(),
            i.vendor_str,
            i.addr.device_id().read(),
            i.name_str
        });
    }

}