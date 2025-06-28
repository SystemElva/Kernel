const std = @import("std");
const root = @import("root");
const main = @import("main.zig");
const debug = root.debug;
const mem = root.mem;
const dev = root.devices;

const allocator = mem.heap.kernel_buddy_allocator;

const HBAMem = main.HBAMem;
const HBAPort = main.HBAPort;
const HBACMDHeader = main.HBACMDHeader;
const HBACMDTable = main.HBACMDTable;
const HBAPRDTEntry = main.HBAPRDTEntry;
const FIS_Reg_H2D = main.FIS_Reg_H2D;

const DiskEntryContext = struct {
    abar: *HBAMem,
    port: *HBAPort
};

const find_cmdslot = main.find_cmdslot;

pub fn init_disk(abar: *HBAMem, port: *HBAPort) void {

    debug.err("Initializing disk...\n", .{});

    stop_cmd(port);
    start_cmd(port);

    var identify_buf: [512]u8 = undefined;
    identify_sata(abar, port, &identify_buf) catch unreachable;

    const w217 = @as(*[256]u16, @ptrCast(@alignCast(&identify_buf)))[217];

    const ctx = allocator.create(DiskEntryContext) catch unreachable;
    ctx.* = .{ .abar = abar, .port = port };
    _ = dev.disk.append_device(
        ctx,
        if (w217 == 1) @as([]const u8, "SSD") else @as([]const u8, "HDD"),
        read_sata,
        write_sata,
        remove
    );
    
}

pub fn identify_sata(abar: *HBAMem, port: *HBAPort, buffer: []u8) !void {
    if (buffer.len != 512) return error.InvalidBufferSize;

    port.is = @bitCast(@as(i32, -1));
    const i_slot = find_cmdslot(port, ((abar.cap >> 8) & 0x1F) + 1);
    if (i_slot == -1) return error.NoCmdSlot;
    const slot: usize = @intCast(i_slot);

    const cmdheaders = mem.ptrFromPhys([*]HBACMDHeader,
        (@as(u64, @intCast(port.clbu)) << 32) | @as(u64, @intCast(port.clb)));
    const cmdheader = &cmdheaders[slot];
    cmdheader.cfl = @sizeOf(FIS_Reg_H2D) / @sizeOf(u32);
    cmdheader.w = 0;
    cmdheader.prdtl = 1;

    const cmdtbl = mem.ptrFromPhys(*HBACMDTable,
        (@as(u64, @intCast(cmdheader.ctbau)) << 32) | @as(u64, @intCast(cmdheader.ctba)));
    @memset(@as([*]u8, @ptrCast(cmdtbl))[0 .. @sizeOf(HBACMDTable) + @sizeOf(HBAPRDTEntry)], 0);

    const phys_buf = mem.physFromPtr(buffer.ptr);
    cmdtbl.prdt_entry(0).* = .{
        .dba  = @intCast(phys_buf & 0xFFFFFFFF),
        .dbau = @intCast(phys_buf >> 32),
        .dbc  = 512 - 1,
        .i    = 1
    };

    const fis: *FIS_Reg_H2D = @ptrCast(&cmdtbl.cfis);
    fis.* = .{
        .fis_type = 0x27,
        .pmport   = 0,
        .c        = 1,
        .command  = 0xEC,
        .featurel = 0,
        .featureh = 0,
        .lba0 = 0, .lba1 = 0, .lba2 = 0,
        .device = 0,
        .lba3 = 0, .lba4 = 0, .lba5 = 0,
        .countl = 0, .counth = 0,
        .icc = 0, .control = 0,
    };

    var spin: usize = 0;
    while ((port.tfd & 0x88) != 0 and spin < 1000000) : (spin += 1) {}
    if (spin == 1000000) return error.PortIsHung;

    port.ci = std.math.shl(u32, 1, slot);

    var timeout: usize = 0;
    while (true) : (timeout += 1) {
        if ((port.ci & std.math.shl(u32, 1, slot)) == 0) break;
        if ((port.is & (1 << 30)) != 0) return error.ReadError;
        if (timeout > 100000) return error.Timeout;
    }

}


// Hooks
pub export fn read_sata(ctx: *anyopaque, sector: u64, buffer: [*]u8, len: usize) bool {

    if (len % 512 != 0) return false;

    const context: *DiskEntryContext = @ptrCast(@alignCast(ctx));
    const abar = context.abar;
    const port = context.port;
    var buf = buffer[0 .. len];

    port.is = @bitCast(@as(i32, -1));
    const i_slot = find_cmdslot(port, ((abar.cap >> 8) & 0x1F) + 1);

    if (i_slot == -1) return false;
    const slot: usize = @bitCast(i_slot);

    const cmdheader_list = mem.ptrFromPhys([*]HBACMDHeader, @as(u64, @intCast(port.clbu)) << 32 | @as(u64, @intCast(port.clb)));
    const cmdheader = &cmdheader_list[slot];
    cmdheader.cfl = @sizeOf(FIS_Reg_H2D) / @sizeOf(u32);

    cmdheader.w = 0;
    cmdheader.prdtl = @truncate(std.math.divCeil(usize, buf.len, 0x4000) catch unreachable);

    const cmdtbl = mem.ptrFromPhys(*HBACMDTable, @as(u64, @intCast(cmdheader.ctbau)) << 32 | @as(u64, @intCast(cmdheader.ctba)));
    const total_prdt_size = @sizeOf(HBACMDTable) + (cmdheader.prdtl - 1) * @sizeOf(HBAPRDTEntry);
    @memset(@as([*]u8, @ptrCast(cmdtbl))[0..total_prdt_size], 0);

    for (0 .. cmdheader.prdtl - 1) |i| {
        const phys_buf = mem.physFromPtr(buf.ptr);
        cmdtbl.prdt_entry(i).dba =  @intCast(phys_buf & 0xFFFFFFFF);
        cmdtbl.prdt_entry(i).dbau = @intCast(phys_buf >> 32);
        cmdtbl.prdt_entry(i).i = 1;
        buf = buf[4096 ..];
    }

    const phys_buf = mem.physFromPtr(buf.ptr);
    cmdtbl.prdt_entry(cmdheader.prdtl - 1).dba =  @truncate(phys_buf & 0xFFFFFFFF);
    cmdtbl.prdt_entry(cmdheader.prdtl - 1).dbau = @truncate(phys_buf >> 32);
    cmdtbl.prdt_entry(cmdheader.prdtl - 1).dbc = @truncate(buf.len - 1);
    cmdtbl.prdt_entry(cmdheader.prdtl - 1).i = 1;

    const cmdfis: *FIS_Reg_H2D = @ptrCast(&cmdtbl.cfis);

    cmdfis.fis_type = 0x27;
    cmdfis.c = 1;
    cmdfis.command = 0x25;

    cmdfis.lba0 = @truncate((sector >> 0) & 0xFF);
    cmdfis.lba1 = @truncate((sector >> 8) & 0xFF);
    cmdfis.lba2 = @truncate((sector >> 16) & 0xFF);
    cmdfis.lba3 = @truncate((sector >> 24) & 0xFF);
    cmdfis.lba4 = @truncate((sector >> 32) & 0xFF);
    cmdfis.lba5 = @truncate((sector >> 40) & 0xFF);

    cmdfis.device = 1 << 6;
    const sector_count = @divExact(buf.len, 512);
    cmdfis.countl = @truncate(sector_count & 0xFF);
    cmdfis.counth = @truncate((sector_count >> 8) * 0xFF);

    var spin: usize = 0;
    while ((port.tfd & (0x88) != 0) and spin < 1000000) : (spin += 1) {}

    if (spin == 1000000) {
        debug.err("Port is hung\n", .{});
        return false;
    }

    port.ci = std.math.shl(u32, 1, slot);

    var timeout: usize = 0;
    while (true) : (timeout += 1) {
        if ((port.ci & std.math.shl(u32, 1, slot)) == 0) break;

        if (timeout >= (1 << 16)) {
            debug.err("Timeout\n", .{});
            return false;
        }
        if ((port.is & (1 << 30)) != 0) {
           debug.err("Read disk error\n", .{});
           return false;
        }
    }

    return true;
}
pub export fn write_sata(ctx: *anyopaque, sector: u64, buffer: [*]u8, len: usize) bool {
    _ = ctx;
    _ = sector;
    _ = buffer;
    _ = len;
    return false;
}
pub export fn remove(ctx: *anyopaque) void {
    const context: *DiskEntryContext = @ptrCast(@alignCast(ctx));
    allocator.destroy(context);
}

fn start_cmd(port: *HBAPort) void {
    while (port.cmd & 0x8000 != 0) {}
    port.cmd |= 0x0010;
    port.cmd |= 0x0001;
}
fn stop_cmd(port: *HBAPort) void {
    port.cmd &= ~@as(u32, 0x0001);
    port.cmd &= ~@as(u32, 0x0010);

    while (true) {
        if (port.cmd & 0x4000 != 0) continue;
        if (port.cmd & 0x8000 != 0) continue;
        break;
    }
}
