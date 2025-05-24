pub inline fn salloc(length: usize) []u8 {
    var ptr: [*]u8 = undefined;
    asm volatile (
        \\ sub %[len], %%rsp
        \\ mov %%rsp, %[out]
        : [out] "=r"(ptr) 
        : [len] "r"(length)
        :
        "rsp", "memory"
    );
    return ptr[0..length];
}

pub inline fn sfree(mem: []u8) void {
    asm volatile (
        \\ add %[len], %%rsp
        :
        : [len] "r"(mem.len)
        : "rsp", "memory"
    );
}
