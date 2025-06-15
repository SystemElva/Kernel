const serial = @import("serial.zig");
const gdt = @import("globalDescriptorTable.zig");
const idt = @import("interruptDescriptorTable.zig");
const pmm = @import("mem/pmm.zig");
const vmm = @import("mem/vmm.zig");

const root = @import("root");
const debug = root.debug;

pub fn init() !void {

    try serial.init();
    debug.err("Serial initialized\n", .{});

    debug.err("Installing GDT...\n", .{});
    gdt.install();
    debug.err("Installing IDT...\n", .{});
    idt.install();

    debug.err("Things done time to memory shit\n", .{});
    pmm.setup();
    vmm.init();
    
}
