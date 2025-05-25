// TODO implement level-5 page mapping (99% unecessary)

const AccessMode = enum(u1) {
    read_only = 0,
    read_write = 1,
};
const Privilege = enum(u1) {
    kernel = 0,
    user = 1
};
const CacheMode = packed union {
    cacheable: packed struct(u2) {
        cache_mode: enum(u1) { write_though = 0, write_back = 1 },
        _rsvd_0: bool = false,
    },
    uncacheable: packed struct(u2) {
        _rsvd_0: u1 = 0,
        _rsvd_2: bool = true,
    },
};

// _available_x are free bits that can be used
// by the kernel.
// _reserved_x must aways be 0!

const PML45 = packed struct(u64) {
    present: bool,
    access: AccessMode,
    privilege: Privilege,
    cache_mode: CacheMode,
    uncacheable: bool,
    accessed: bool,

    _available_0: u1,
    _reserved_0: u1 = 0,
    _available_1: u4,
    physaddr: u40,
    _reserved_1: u11,
    no_code: bool,

    const physaddr_mask = makeTruncMask(@This(), "physaddr");
    pub inline fn get_phys_addr(self: @This()) usize {
        return @as(u64, @bitCast(self)) & physaddr_mask;
    }
    pub inline fn set_phys_addr(self: *@This(), addr: usize) void {
        self.physaddr = @truncate(addr >> 12);
    }
};

const PDPTE = packed struct(u64) {
    present: bool,
    access: AccessMode,
    privilege: Privilege,
    cache: CacheMode,
    accessed: bool,

    dirty: bool,
    is_gb_page: bool,
    global: bool,
    _reserved_0: u3 = 0,

    physaddr: packed union {

        // If being used as 1GB page
        gb_page: packed struct(u51) {
            pat: bool,
            _reserved_0: u17 = 0,
            physaddr: u22, // must be left shifted 30 to get true addr
            _reserved_1: u7 = 0,
            protection_key: u4, // ignored if pointing to page directory
        },

        // If being used as a normal PDTE
        pd_ptr: packed struct(u51) {
            addr: u40, // must be left shifted 12 to get true addr
            _reserved_0: u7 = 0,
            _reserved_2: u4 = 0,
        },
    
    },

    no_code: bool,

    pub fn get_phys_addr(self: @This()) usize {
        if (self.is_gb_page) {
            return @as(u52, @intCast(self.physaddr.gb_page.physaddr)) << 30;
        } else {
            return @as(u52, @intCast(self.physaddr.pd_ptr.addr)) << 12;
        }
    }
    pub fn set_phys_addr(self: *@This(), addr: usize) void {
        if (self.is_gb_page) {
            self.physaddr.gb_page.physaddr = @truncate(addr >> 30);
        } else {
            self.physaddr.pd_ptr.addr = @truncate(addr >> 12);
        }
    }
};

const PDE = packed struct(u64) {
    present: bool,
    access: AccessMode,
    privilege: Privilege,
    cache: CacheMode,
    accessed: bool,
    dirty: bool,

    is_mb_page: bool,
    global: bool,
    _ignored1: u3 = 0,

    physaddr: packed union {

        // If being used as 1MB page
        mb_page: packed struct(u51) {
            pat: bool,
            _reserved_0: u8 = 0,
            physaddr: u31, // must be left shifted 21 to get true addr
            _reserved_1: u7 = 0,
            protection_key: u4, // ignored if pointing to page table
        },

        // If being used as a normal PDE
        pd_ptr: packed struct(u51) {
            addr: u40, // must be left shifted 12 to get true addr
            _reserved_0: u7 = 0,
            _ignored1: u4 = 0,
        },

    },

    no_code: bool,

    pub fn get_phys_addr(self: @This()) usize {
        if (self.is_mb_page) {
            // 2mb page
            return @as(u52, @intCast(self.physaddr.mb_page.physaddr)) << 21;
        } else {
            return @as(u52, @intCast(self.physaddr.pd_ptr.addr)) << 12;
        }
    }

    pub fn set_phys_addr(self: *@This(), addr: usize) void {
        if (self.is_mb_page) {
            // 2mb page
            self.physaddr.mb_page.physaddr = @truncate(addr >> 21);
        } else {
            self.physaddr.pd_ptr.addr = @truncate(addr >> 12);
        }
    }
};

const PTE = packed struct(u64) {
    present: bool,
    access: AccessMode,
    privilege: Privilege,
    cache: CacheMode,
    accessed: bool,
    dirty: bool,
    attribute_table: bool,
    global: bool,
    _reserved_0: u3 = 0,
    physaddr: u40, // must be left shifted 12 to get true addr
    _reserved_1: u7 = 0,
    protection_key: u4,
    no_code: bool,

    const physaddr_mask = makeTruncMask(@This(), .physaddr);
    pub fn get_phys_addr(self: @This()) usize {
        return @as(u64, @bitCast(self)) & physaddr_mask;
    }

    pub fn set_phys_addr(self: *@This(), addr: usize) void {
        self.physaddr = @truncate(addr >> 12);
    }
};


// generates a mask to isolate a field of a packed struct while keeping it shifted relative to its bit offset in the struct.
// the field's value is effectively left shifted by its bit offset in the struct and bits outside the field are masked out
fn makeTruncMask(comptime T: type, comptime field: []const u8) @Type(.{ .@"int" = .{ .signedness = .unsigned, .bits = @bitSizeOf(T) } }) {
    const offset = @bitOffsetOf(T, field);
    const size = @bitSizeOf(@TypeOf(@field(@as(T, undefined), field)));

    const size_mask = (1 << size) - 1;
    return size_mask << offset;
}
