pub const BootInfo = struct {

    kernel_physical_start: usize,
    kernel_virtual_start: usize,
    hhdm_address_offset: usize,

    device_tree_blob: ?*anyopaque,

    memoryMap: []*MemoryMapEntry,
    framebuffer: Framebuffer,
};

pub const Framebuffer = struct {
    framebuffer: []u8,
    width: u64,
    height: u64,
    pixels_per_scan_line: u64,
};

// FIXME It is marked as external so i suppose it will be limine-dependant
pub const MemoryMapEntry = struct {
    base: u64,
    size: u64,
    type: RegionType,
};

pub const RegionType = enum(u64) {
    usable,
    reserved,
    acpi_reclaimable,
    acpi_nvs,
    bad_memory,
    bootloader_reclaimable,
    kernel_and_modules,
    framebuffer,
};
