const std = @import("std");
const boot = @import("../boot.zig");
const root = @import("root");
const limine = @import("limine.zig");

// limine requests
pub export var base_revision: limine.BaseRevision = .{ .revision = 3 };
pub export var framebuffer_request: limine.FramebufferRequest = .{};

pub export fn __boot_entry__() callconv(.C) noreturn {
    
    // TODO enable SIMD instructions

    if (framebuffer_request.response == null) done();
    if (framebuffer_request.response.?.framebuffer_count < 1) done();

    const fbuffer = framebuffer_request.response.?.framebuffers_ptr[0];
    const fbuffer_size = fbuffer.pitch * fbuffer.height;

    const boot_info: boot.BootInfo = .{
        .framebuffer = .{
            .framebuffer = fbuffer.address[0 .. fbuffer_size],
            .width = fbuffer.width,
            .height = fbuffer.height,
            .pps = fbuffer.pitch
        }
    };

    root.main(boot_info);
    while (true) {}
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

