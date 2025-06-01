const std = @import("std");
const boot = @import("../boot.zig");
const root = @import("root");
const limine = @import("limine.zig");

// limine requests
pub export var base_revision: limine.BaseRevision = .{ .revision = 3 };
pub export var framebuffer_request: limine.FramebufferRequest = .{};
pub export var memory_map_request: limine.MemoryMapRequest = .{};
pub export var kernel_addr_request: limine.KernelAddressRequest = .{};
pub export var hhdm_request: limine.HhdmRequest = .{};

pub export fn __boot_entry__() callconv(.C) noreturn {
    
    // TODO enable SIMD instructions

    if (framebuffer_request.response == null) done();
    if (framebuffer_request.response.?.framebuffer_count < 1) done();
    if (memory_map_request.response == null) done();
    if (kernel_addr_request.response == null) done();
    if (hhdm_request.response == null) done();

    const fbuffer = framebuffer_request.response.?.framebuffers_ptr[0];
    const fbuffer_size = fbuffer.pitch * fbuffer.height;

    const mmap = memory_map_request.response.?;
    const addr = kernel_addr_request.response.?;
    const hhdm = hhdm_request.response.?;

    const boot_info: boot.BootInfo = .{
        .kernel_base_physical = addr.physical_base,
        .kernel_base_virtual = addr.virtual_base,
        .hhdm_base_offset = hhdm.offset,

        .framebuffer = .{
            .framebuffer = fbuffer.address[0 .. fbuffer_size],
            .width = fbuffer.width,
            .height = fbuffer.height,
            .pps = fbuffer.pitch
        },

        .memory_map = @ptrCast(mmap.entries_ptr[0..mmap.entry_count])
    };

    root.main(boot_info);
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

