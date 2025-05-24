const gdt = @import("globalDescriptorTable.zig");
const pmm = @import("mem/pmm.zig");

pub fn init() !void {

    gdt.install();
    pmm.setup();
    
}
