const std = @import("std");
const ports = @import("ports.zig");

pub const com_port: [4]u16 = .{0x3F8, 0x2F8, 0x3E8, 0x2E8};

pub const SerialWriter = std.io.Writer(
    *anyopaque,
    error{},
    serial_out
);

pub fn init() !void {

    for (0..4) |i| {
        // Disabling device interrupts
        ports.outb(com_port[i] + 1, 0x00);

        // Set BAUD bit
        ports.outb(com_port[i] + 3, 0x80);

        ports.outb(com_port[i] + 0, 0x03);
        ports.outb(com_port[i] + 1, 0x00);

        // Setting line control register
        ports.outb(com_port[i] + 3, 0x03);

        // This set some things in the FIFO Control register:
        //   - the first bit enables FIFO buffers
        //   - the second bit clears the receive FIFO buffer
        //   - the third bit clears the transmit FIFO buffer
        //     - Those both bits will clear them by themselves after they cleared their FIFO buffer
        //   - the fourth bit is not used here
        //   - the fifth and sixth bit are reserved
        //   - the seventh and eigth bit sets the interrupt trigger level (which specifies how much data must be received in the FIFO receive buffer before triggering a Received Data Available Interrupt).
        //     We want this to be the maximum as we don't want any interrupts, so the least possible computation is wasted.
        ports.outb(com_port[i] + 2, 0xc7);

        // This sets some bits in the Modem Control Register.
        //   - the first bit controls the Data Terminal Ready pin
        //   - the second bit controls the Rquest to Send pin
        //   - the third bit us unused in PC implementations
        //   - the fourth bit controls a hardware pin which is used to enable the IRQ in PC implementations.
        //   - the fifth bit provides a local loopback feature for diagnostic testing of the UART
        //   - the sixth to eigth bytes are unused
        ports.outb(com_port[i] + 4, 0x0b);

        uart_putchar(@truncate(i), '\n');
    }
}

pub inline fn writer(dev: u8) SerialWriter {
    return .{ .context = @ptrFromInt(dev + 1) };
}

fn serial_out(dev: *anyopaque, bytes: []const u8) !usize {
    const devi: u8 = @truncate(@intFromPtr(dev));
    uart_puts(devi - 1, bytes);
    return bytes.len;
}


inline fn is_buffer_empty(dev: u8) bool {
    return (ports.inb(com_port[dev] + 5) & 0x20) != 0;
}

pub inline fn uart_putchar(dev: u8, char: u8) void {
    while (!is_buffer_empty(dev)) {}
    ports.outb(com_port[dev], char);
}

pub inline fn uart_puts(dev: u8, str: []const u8) void {
    for (str) |char| {
        uart_putchar(dev, char);
    }
}
