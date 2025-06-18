const serial = @import("serial.zig");
const gdt = @import("globalDescriptorTable.zig");
const idt = @import("interruptDescriptorTable.zig");
const pmm = @import("mem/pmm.zig");
const vmm = @import("mem/vmm.zig");
const pic = @import("pic.zig");

const root = @import("root");
const debug = root.debug;

pub fn init() !void {

    try serial.init();
    debug.err("Serial initialized\n", .{});

    debug.err("Installing GDT...\n", .{});
    gdt.install();
    debug.err("Installing IDT...\n", .{});
    idt.install();

    debug.err("Setting up Physical Memory Management...\n", .{});
    pmm.setup();
    debug.err("Setting up Virtual Memory Management...\n", .{});
    vmm.init();
    
}

pub fn finalize() !void {
    
    debug.err("Setting up Programable Interrupt Controller...\n", .{});
    pic.setup();

}
