const std = @import("std");
const Build = std.Build;
const Step = Build.Step;
const Target = std.Target;
const builtin = @import("builtin");

// imageBuilder dependences references
const imageBuilder = @import("deps/image-builder/main.zig");
const MiB = imageBuilder.size_constants.MiB;
const GPTr = imageBuilder.size_constants.GPT_reserved_sectors;

pub fn build(b: *std.Build) void {
    b.exe_dir = "zig-out/";

    const target = Target.Query{
        .cpu_arch = .aarch64,
        .os_tag = .freestanding,
        .abi = .none,
        .ofmt = .elf,
    };
    const optimize = b.standardOptimizeOption(.{});

    var install_bootloader_step = addDummyStep(b, "Install Bootloader");
    {
        //install_bootloader_step.dependOn(&b.addInstallFile(b.path("deps/limine/limine_BOOTX64.EFI"), "disk/EFI/BOOT/BOOTX64.EFI").step);
        install_bootloader_step.dependOn(&b.addInstallFile(b.path("deps/limine/limine_BOOTAA64.EFI"), "disk/EFI/BOOT/BOOTAA64.EFI").step);
        install_bootloader_step.dependOn(&b.addInstallFile(b.path("deps/limine/limine_config.txt"), "disk/boot/limine/limine.conf").step);
        //install_bootloader_step.dependOn(&b.addInstallFile(b.path("deps/limine/limine-bios.sys"), "disk/boot/limine/limine-bios.sys").step);
    }

    // kernel
    const kernel_mod = b.addModule("kernel", .{
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .code_model = .small,
        .red_zone = false,
    });
    const kernel_exe = b.addExecutable(.{
        .name = "kernelx64",
        .root_module = kernel_mod,
    });
    
    kernel_exe.entry = undefined;
    kernel_exe.setLinkerScript(b.path("linkScript.ld"));
    
    const kernel_install = b.addInstallArtifact(kernel_exe, .{
        .dest_sub_path = "disk/kernelaa64"
    });

    // generate disk image
    var disk = imageBuilder.addBuildGPTDiskImage(b, 20*MiB + GPTr, "lumiOS.img");
    disk.addPartition(.vFAT, "main", "zig-out/disk", 15*MiB);

    disk.step.dependOn(install_bootloader_step);
    disk.step.dependOn(&kernel_install.step);

    const run_qemu = b.addSystemCommand(&.{
        "qemu-system-aarch64",
        
        "-cpu", "cortex-a57",
        "-machine", "virt",
        "-bios", "deps/debug/OVMF.fd", // for UEFI emulation
        "-m", "2G",

        // serial, video, etc
        "-serial", "file:zig-out/serial.txt",
        "-monitor", "mon:stdio",
        "-display", "gtk,zoom-to-fit=on",

        // Aditional devices
        "-device", "ramfb",
        "-device", "virtio-blk-device,drive=hd0,id=blk1",

        //"-usb",
        "-device", "qemu-xhci,id=usb",
        "-device", "usb-mouse",
        "-device", "usb-kbd",

        // Debug
        "-D", "zig-out/log.txt",
        "-d", "int,cpu_reset",
        //"--no-reboot",
        //"--no-shutdown",
        //"-trace", "*xhci*",
        //"-s", "-S",

        // Disk
        "-drive", "id=hd0,file=zig-out/lumiOS.img,format=raw,if=none",
    });

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
