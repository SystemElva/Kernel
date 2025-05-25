const serial = @import("serial.zig");
const gdt = @import("globalDescriptorTable.zig");
const pmm = @import("mem/pmm.zig");

pub fn init() !void {

    try serial.init();
    gdt.install();
    pmm.setup();
    
}
