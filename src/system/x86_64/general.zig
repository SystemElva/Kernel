const gdt = @import("globalDescriptorTable.zig");

pub fn init() !void {

    gdt.install();
    
}
