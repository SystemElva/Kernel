const serial = @import("serial.zig");
const gdt = @import("globalDescriptorTable.zig");
const idt = @import("interruptDescriptorTable.zig");
const pmm = @import("mem/pmm.zig");
const vmm = @import("mem/vmm.zig");
const pic = @import("pic.zig");
const ports = @import("ports.zig");

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

    debug.err("Setting up Programable Interval Timer...\n", .{});
    setup_timer_interval();

}

fn setup_timer_interval()  void {
    const frquency = 1000; // ms
    const divisor: u16 = 1_193_182 / frquency;

    ports.outb(0x43, 0x36);
    ports.outb(0x40, @intCast(divisor & 0xFF));
    ports.outb(0x40, @intCast((divisor >> 8) & 0xFF));
}
