const root = @import("root");
const system = root.system;

const device_tree_parser = @import("device_tree_parser.zig");

pub fn init() !void {

    const bi = root.get_boot_info();

    if (bi.device_tree_blob == null) return error.NoDeviceTree;

    const dtb_bytes: [*]const u8 = @ptrCast(@alignCast(bi.device_tree_blob.?));

    try device_tree_parser.parse_dtb(dtb_bytes);

}
