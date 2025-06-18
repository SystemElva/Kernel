const std = @import("std");
const root = @import("root");
const ports = root.system.ports;
const debug =root.debug;
const pci_global = @import("../../pci.zig");

pub const Addr = @import("Addr.zig");

const PciDevice = pci_global.PciDevice;
const DeviceList = pci_global.DeviceList;

// TODO implement PCI domains (Usually not present in PCs but meh)

pub fn list_devices(list: *DeviceList) !void {

    debug.print("Scanning bus root...\n", .{});
    bus_scan(0, list);
    debug.print("Scan complete!\n", .{});

}


fn bus_scan(bus: u8, list: *DeviceList) void {
    inline for (0..(1 << 5)) |device| {
        device_scan(bus, @intCast(device), list);
    }
}

pub fn device_scan(bus: u8, device: u5, list: *DeviceList) void {
    const nullfunc: Addr = .{ .bus = bus, .device = device, .function = 0 };

    if (nullfunc.header_type().read() == 0xFFFF) return;

    function_scan(nullfunc, list);

    if (nullfunc.header_type().read() & 0x80 == 0) return;

    inline for (0..((1 << 3) - 1)) |function| {
        function_scan(.{ .bus = bus, .device = device, .function = @intCast(function + 1) }, list);
    }
}

pub fn function_scan(addr: Addr, list: *DeviceList) void {
    if (addr.vendor_id().read() == 0xFFFF) return;

    // Append devices to the devices list
    // If bridge, iterate though it

    // Bridge device
    if (addr.base_class().read() == 0x06) {

        var still_unrecognized = false;

        switch (addr.sub_class().read()) {
            0x00 => debug.err("Host bridge (ignoring)\n", .{}),
            0x04 => {
                debug.err("PCI-to-PCI bridge", .{});
                if ((addr.header_type().read() & 0x7F) != 0x01) {

                    debug.err(" (Not PCI-to-PCI bridge header type!)\n", .{});

                } else {

                    const secondary_bus = addr.secondary_bus().read();
                    debug.err(", recursively scanning bus {0X}\n", .{secondary_bus});
                    bus_scan(secondary_bus, list);
                    
                }
            },
            else => still_unrecognized = true
        }

        if (!still_unrecognized) return;
    }

    list.append(.{ .addr = addr }) catch @panic("OOM");

}

