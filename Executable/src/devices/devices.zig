const std = @import("std");
const root = @import("root");
const sys = root.system;

pub const pci = @import("pci.zig");
pub const acpi = @import("acpi.zig");

pub fn init() !void {

    pci.init();
    try pci.list_pci_devices();

    acpi.init();

}
