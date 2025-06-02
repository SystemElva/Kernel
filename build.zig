const std = @import("std");
const Build = std.Build;
const Step = Build.Step;
const Target = std.Target;
const builtin = @import("builtin");

// imageBuilder dependences references
const imageBuilder = @import("deps/image-builder/main.zig");
const MiB = imageBuilder.size_constants.MiB;
const GPTr = imageBuilder.size_constants.GPT_reserved_sectors;

// Supported archtectures
const SArch = enum {
    x86_64,
    aarch64
};

pub fn build(b: *std.Build) void {
    b.exe_dir = "zig-out/";

    const target_archtecture_response = b.option(Target.Cpu.Arch, "tarch", "Target archtecture") orelse builtin.cpu.arch;
    const target_archtecture: SArch = switch (target_archtecture_response) {
        .x86_64 => .x86_64,
        .aarch64 => .aarch64,
        else => std.debug.panic("{s} archtecture is not implemented!", .{@tagName(target_archtecture_response)})
    };

    var target = Target.Query {
        .cpu_arch = target_archtecture_response,
        .os_tag = .freestanding,
        .abi = .none,
        .ofmt = .elf,
    };
    const optimize = b.standardOptimizeOption(.{});

    switch (target_archtecture) {
        .x86_64 => {
            const Feature = std.Target.x86.Feature;

            // Disable SIMD registers TODO some way to avoid it
            target.cpu_features_sub.addFeature(@intFromEnum(Feature.mmx));
            target.cpu_features_sub.addFeature(@intFromEnum(Feature.sse));
            target.cpu_features_sub.addFeature(@intFromEnum(Feature.sse2));
            target.cpu_features_sub.addFeature(@intFromEnum(Feature.avx));
            target.cpu_features_sub.addFeature(@intFromEnum(Feature.avx2));

            target.cpu_features_add.addFeature(@intFromEnum(Feature.soft_float));

        },
        .aarch64 => {
            const features = std.Target.aarch64.Feature;
            target.cpu_features_sub.addFeature(@intFromEnum(features.fp_armv8));
            target.cpu_features_sub.addFeature(@intFromEnum(features.crypto));
            target.cpu_features_sub.addFeature(@intFromEnum(features.neon));
        }
    }

    var install_bootloader_step = addDummyStep(b, "Install Bootloader");
    switch (target_archtecture) {
        .aarch64 => install_bootloader_step.dependOn(&b.addInstallFile(b.path("deps/limine/BOOTAA64.EFI"), "disk/EFI/BOOT/BOOTAA64.EFI").step),
        .x86_64 => install_bootloader_step.dependOn(&b.addInstallFile(b.path("deps/limine/BOOTX64.EFI"), "disk/EFI/BOOT/BOOTX64.EFI").step),
    }
    install_bootloader_step.dependOn(&b.addInstallFile(b.path("deps/limine/config.txt"), "disk/boot/limine/limine.conf").step);

    // kernel module
    const kernel_mod = b.addModule("kernel", .{
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .red_zone = false,
    });
    kernel_mod.code_model = switch (target_archtecture) {
        .aarch64 => .small,
        .x86_64 => .kernel
    };
    
    // kernel executable
    const kernel_exe = b.addExecutable(.{
        .name = "kernel",
        .root_module = kernel_mod,
    });
    kernel_exe.entry = .{ .symbol_name = "__boot_entry__" };
    switch (target_archtecture) {
        .aarch64 => kernel_exe.setLinkerScript(b.path("link/aarch64.ld")),
        .x86_64 => kernel_exe.setLinkerScript(b.path("link/x86_64.ld"))
    }
    
    // kernel install
    const kernel_install = b.addInstallArtifact(kernel_exe, .{
        .dest_sub_path = "disk/kernel"
    });

    // generate disk image
    var disk = imageBuilder.addBuildGPTDiskImage(b, 20*MiB + GPTr, "SystemElva.img");
    disk.addPartition(.vFAT, "main", "zig-out/disk", 15*MiB);

    disk.step.dependOn(install_bootloader_step);
    disk.step.dependOn(&kernel_install.step);

    // Generate qemu args and run it
    const Rope = std.ArrayList([]const u8);
    var qemu_args = Rope.init(b.allocator);
    defer qemu_args.deinit();

    switch (target_archtecture) {
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
            qemu_args.appendSlice(&.{"-bios", "deps/debug/x86_64_OVMF.fd"}) catch @panic("OOM");
        }
    }

    // general options
    qemu_args.appendSlice(&.{"-m", "2G"}) catch @panic("OOM");

    qemu_args.appendSlice(&.{"-serial", "file:zig-out/com1.txt"}) catch @panic("OOM");
    qemu_args.appendSlice(&.{"-monitor", "mon:stdio"}) catch @panic("OOM");
    qemu_args.appendSlice(&.{"-display", "gtk,zoom-to-fit=on"}) catch @panic("OOM");

    qemu_args.appendSlice(&.{"-D", "zig-out/log.txt"}) catch @panic("OOM");
    qemu_args.appendSlice(&.{"-d", "int,cpu_reset"}) catch @panic("OOM");
    qemu_args.appendSlice(&.{"--no-reboot"}) catch @panic("OOM");
    qemu_args.appendSlice(&.{"--no-shutdown"}) catch @panic("OOM");
    //qemu_args.appendSlice(&.{"-trace", "*xhci*"}) catch @panic("OOM");
    //qemu_args.appendSlice(&.{"-s", "-S"}) catch @panic("OOM");

    qemu_args.appendSlice(&.{"-qmp", "unix:qmp.socket,server,nowait"}) catch @panic("OOM");

    const run_qemu = b.addSystemCommand(qemu_args.items);

    // default (only build)
    b.getInstallStep().dependOn(&disk.step);

    run_qemu.step.dependOn(b.getInstallStep());

    // build and run
    const run_step = b.step("run", "Run the OS in qemu");
    run_step.dependOn(&run_qemu.step);
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
