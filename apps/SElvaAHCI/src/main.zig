const std = @import("std");
const root = @import("root");
const modules = root.modules;
const sys = root.system;
const debug = root.debug;
const pci = root.devices.pci;

const PciDevice = pci.PciDevice;

const allocator = root.mem.heap.kernel_allocator;


// Module information
pub const module_name: [*:0]const u8 =     "SElvaAHCI";
pub const module_version: [*:0]const u8 =  "0.1.0";
pub const module_author: [*:0]const u8 =   "System Elva Team";
pub const module_liscence: [*:0]const u8 = "MPL-2.0";

pub fn init() callconv(.c) bool {
    debug.print("Hello, SElvaAHCI!\n", .{});

    const query: [*]const pci.PciDeviceQuery = &[_]pci.PciDeviceQuery {
        .byClass(0x01, 0x06, 0), // SATA controller class
        .endOfChain()
    };

    debug.print("Probing PCI devices...\n", .{});
    pci.pci_device_probe(query, device_probe);

    debug.print("Returning...\n", .{});
    return true;
}
pub fn deinit() callconv(.c) void {

}

pub fn device_probe(dev: *PciDevice) callconv(.c) bool {

    // It will swith-case by the vendor and device to
    // assign the correct names to it
    name_device(dev);

    debug.print("Probing PCI device: {X:0>2}:{X:0>2}.{X:0>1} [{X:0>2}:{X:0>2}] {s}\n", .{
        dev.get_bus(),
        dev.get_device(),
        dev.get_function(),
        dev.addr.base_class().read(),
        dev.addr.sub_class().read(),
        dev.name_string,
    });
    
    
    
    return true;
}

fn name_device(dev: *PciDevice) void {

    dev.type_str = "SATA Controller";
    switch (dev.addr.vendor_id().read()) {
        else => |v| debug.err("Unknown vendor ID {X:0>4}", .{v}),

        0x8086 => {
            dev.vendor_str = "Intel";
            switch (dev.addr.device_id().read()) {
                else => |v| debug.err("Unknown device ID {X:0>4} from vendor {s}", .{v, dev.vendor_str}),

                0x2922 => dev.name_str = "Intel ICH9 SATA Controller [AHCI mode]",
                0x1C02 => dev.name_str = "Intel 6 Series/C200 Series Chipset Family SATA AHCI Controller",
                0x8C02 => dev.name_str = "Intel 8 Series/C220 Chipset Family SATA Controller 1 [AHCI mode]",
                0x9C03 => dev.name_str = "Intel 9 Series Chipset Family SATA Controller [AHCI Mode]"

            }
        },

        0x1022 => {
            dev.vendor_str = "AMD";
            switch (dev.addr.device_id().read()) {
                else => |v| debug.err("Unknown device ID {X:0>4} from vendor {s}", .{v, dev.vendor_str}),

                0x7801 => dev.name_str = "AMD FCH SATA Controller [AHCI mode]",
                0x4391 => dev.name_str = "AMD SB7x0/SB8x0/SB9x0 SATA Controller [AHCI mode]"

            }
        },

        0x1b21 => {
            dev.vendor_str = "ASMedia Technology Inc.";
            switch (dev.addr.device_id().read()) {
                else => |v| debug.err("Unknown device ID {X:0>4} from vendor {s}", .{v, dev.vendor_str}),

                0x0612 => dev.name_str = "ASMedia ASM1062 Serial ATA Controller",
                0x0611 => dev.name_str = "ASMedia ASM1061 SATA Controller"

            }
        },

        0x1b4b => {
            dev.vendor_str = "Marvell Technology Group Ltd.";
            switch (dev.addr.device_id().read()) {
                else => |v| debug.err("Unknown device ID {X:0>4} from vendor {s}", .{v, dev.vendor_str}),

                0x9123 => dev.name_str = "Marvell 88SE9123 PCIe SATA 6 Gb/s Controller",
                0x9230 => dev.name_str = "Marvell 88SE9230 PCIe SATA 6 Gb/s Controller"

            }
        },

    }

}
