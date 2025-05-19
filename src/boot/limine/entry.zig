const std = @import("std");
const limine = @import("limine.zig");
const boot = @import("../boot.zig");
const root = @import("root");

pub export var framebuffer_request: limine.FramebufferRequest = .{};
pub export var memory_map_request: limine.MemoryMapRequest = .{};
pub export var device_tree_blob_request: limine.DeviceTreeBlobRequest = .{};
pub export var kernel_addr_request: limine.KernelAddressRequest = .{};
pub export var hhdm_request: limine.HhdmRequest = .{};
pub export var base_revision: limine.BaseRevision = .{ .revision = 2 };


export fn __boot_entry__() callconv(.C) noreturn {
    
    if (framebuffer_request.response == null) done();
    if (framebuffer_request.response.?.framebuffer_count < 1) done();
    if (memory_map_request.response == null) done();
    if (kernel_addr_request.response == null) done();
    if (hhdm_request.response == null) done();
    if (device_tree_blob_request.response == null) done();

    const fbuffer = framebuffer_request.response.?.framebuffers_ptr[0];
    const mmap = memory_map_request.response.?;
    const addr = kernel_addr_request.response.?;
    const hhdr = hhdm_request.response.?;
    const dtb = device_tree_blob_request.response.?;

    const boot_info = boot.BootInfo {
        .kernel_physical_start = addr.physical_base,
        .kernel_virtual_start = addr.virtual_base,
        .hhdm_address_offset = hhdr.offset,

        .device_tree_blob = dtb.dtb,
        .memoryMap = mmap.entries_ptr[0 .. mmap.entry_count],
        .framebuffer = .{
            .framebuffer = fbuffer.address[0 .. fbuffer.pitch * fbuffer.height],
            .height = fbuffer.height,
            .width = fbuffer.width,
            .pixels_per_scan_line = fbuffer.pitch,
        },
    };

    root.main(boot_info) catch done();
    unreachable;
}

fn done() noreturn {
    // Error here, the CPU is hard resetted
    // after tripple falt

    std.mem.doNotOptimizeAway({
        const a: u64 = 1;
        var b: u64 = 0;
        _ = a / b;
        b = undefined;
    });

    unreachable;
}
