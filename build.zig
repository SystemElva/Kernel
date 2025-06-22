const std = @import("std");
const Build = std.Build;
const Step = Build.Step;
const Target = std.Target;
const builtin = @import("builtin");

// imageBuilder dependences references
const imageBuilder = @import("_dependences/image-builder/main.zig");
const MiB = imageBuilder.size_constants.MiB;
const GPTr = imageBuilder.size_constants.GPT_reserved_sectors;


pub fn build(b: *std.Build) void {
    b.exe_dir = "zig-out/";

    const target_arch = b.option(Target.Cpu.Arch, "tarch", "Target archtecture") orelse builtin.cpu.arch;
    // Test archtecture
    switch (target_arch) {
        .x86_64,
        .aarch64 => {}, // supported archtecture
        else => std.debug.panic("{s} archtecture is currently not implemented!", .{@tagName(target_arch)})
    }

    var install_bootloader_step = addDummyStep(b, "Install Bootloader");
    switch (target_arch) {
        .aarch64 => install_bootloader_step.dependOn(&b.addInstallFile(b.path("_dependences/limine/BOOTAA64.EFI"), "disk/EFI/BOOT/BOOTAA64.EFI").step),
        .x86_64 => install_bootloader_step.dependOn(&b.addInstallFile(b.path("_dependences/limine/BOOTX64.EFI"), "disk/EFI/BOOT/BOOTX64.EFI").step),
        else => unreachable
    }
    install_bootloader_step.dependOn(&b.addInstallFile(b.path("_dependences/limine/config.txt"), "disk/boot/limine/limine.conf").step);

    // kernel 
    const kernel_dep = b.dependency("core", .{});
    const kernel = kernel_dep.artifact("kernel");
    const kernel_install = b.addInstallFile(kernel.getEmittedBin(), "disk/kernel");

    // generate disk image
    var disk = imageBuilder.addBuildGPTDiskImage(b, 20*MiB + GPTr, "SystemElva.img");
    disk.addPartition(.vFAT, "main", "zig-out/disk", 15*MiB);

    disk.step.dependOn(install_bootloader_step);
    disk.step.dependOn(&kernel_install.step);

    // Generate qemu args and run it
    const Rope = std.ArrayList([]const u8);
    var qemu_args = Rope.init(b.allocator);
    defer qemu_args.deinit();

    switch (target_arch) {
        .aarch64 => {
            qemu_args.append("qemu-system-aarch64") catch @panic("OOM");

            qemu_args.appendSlice(&.{"-cpu", "cortex-a57"}) catch @panic("OOM");
            qemu_args.appendSlice(&.{"-machine", "virt"}) catch @panic("OOM");

            qemu_args.appendSlice(&.{"-device", "ramfb"}) catch @panic("OOM");
            qemu_args.appendSlice(&.{"-device", "virtio-blk-device,drive=hd0,id=blk1"}) catch @panic("OOM");
            qemu_args.appendSlice(&.{"-drive", "id=hd0,file=zig-out/SystemElva.img,format=raw,if=none"}) catch @panic("OOM");

            // for UEFI emulation
            qemu_args.appendSlice(&.{"-bios", "deps/debug/aarch64_OVMF.fd"}) catch @panic("OOM");

            // as aarch64 don't have PS/2
            qemu_args.appendSlice(&.{"-device", "qemu-xhci,id=usb"}) catch @panic("OOM");
            qemu_args.appendSlice(&.{"-device", "usb-mouse"}) catch @panic("OOM");
            qemu_args.appendSlice(&.{"-device", "usb-kbd"}) catch @panic("OOM");
        },
        .x86_64 => {
            qemu_args.append("qemu-system-x86_64") catch @panic("OOM");

            qemu_args.appendSlice(&.{"-machine", "q35"}) catch @panic("OOM");

            qemu_args.appendSlice(&.{"-device", "ahci,id=ahci"}) catch @panic("OOM");
            qemu_args.appendSlice(&.{"-device", "ide-hd,drive=drive0,bus=ahci.0"}) catch @panic("OOM");
            qemu_args.appendSlice(&.{"-drive", "id=drive0,file=zig-out/SystemElva.img,format=raw,if=none"}) catch @panic("OOM");

            // for UEFI emulation
            qemu_args.appendSlice(&.{"-bios", "_dependences/debug/x86_64_OVMF.fd"}) catch @panic("OOM");
        },
        else => unreachable
    }

    // general options
    qemu_args.appendSlice(&.{"-m", "2G"}) catch @panic("OOM");

    qemu_args.appendSlice(&.{"-serial", "file:zig-out/stdout.txt"}) catch @panic("OOM");
    qemu_args.appendSlice(&.{"-serial", "file:zig-out/stderr.txt"}) catch @panic("OOM");

    qemu_args.appendSlice(&.{"-monitor", "mon:stdio"}) catch @panic("OOM");
    qemu_args.appendSlice(&.{"-display", "gtk,zoom-to-fit=on"}) catch @panic("OOM");

    qemu_args.appendSlice(&.{"-D", "zig-out/log.txt"}) catch @panic("OOM");
    qemu_args.appendSlice(&.{"-d", "int,mmu,cpu_reset,guest_errors,strace"}) catch @panic("OOM");
    qemu_args.appendSlice(&.{"--no-reboot"}) catch @panic("OOM");
    qemu_args.appendSlice(&.{"--no-shutdown"}) catch @panic("OOM");
    //qemu_args.appendSlice(&.{"-trace", "*xhci*"}) catch @panic("OOM");
    //qemu_args.appendSlice(&.{"-s", "-S"}) catch @panic("OOM");

    qemu_args.appendSlice(&.{"-qmp", "unix:qmp.socket,server,nowait"}) catch @panic("OOM");

    const run_qemu = b.addSystemCommand(qemu_args.items);
    const after_run = b.addSystemCommand(&.{"bash", "afterrun.sh"});

    // default (only build)
    b.getInstallStep().dependOn(&disk.step);

    run_qemu.step.dependOn(b.getInstallStep());
    after_run.step.dependOn(&run_qemu.step);

    // build and run
    const run_step = b.step("run", "Run the OS in qemu");
    run_step.dependOn(&after_run.step);
}

fn addDummyStep(b: *Build, name: []const u8) *Step {
    const step = b.allocator.create(Step) catch unreachable;
    step.* = Step.init(.{
        .id = .custom,
        .name = name,
        .owner = b
    });
    return step;
}
