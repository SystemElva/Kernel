pub const BootInfo = struct {
    framebuffer: Framebuffer,
};

pub const Framebuffer = struct {
    framebuffer: []u8,
    width: u64,
    height: u64,
    pps: u64,
};
