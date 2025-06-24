const std = @import("std");
const builtin = @import("builtin");
const Build = std.Build;
const Target = std.Target;
const Step = Build.Step;

pub fn build(b: *std.Build) void {

    const target_arch = b.option(Target.Cpu.Arch, "tarch", "Target archtecture") orelse builtin.cpu.arch;

    var target = Target.Query {
        .cpu_arch = target_arch,
        .os_tag = .freestanding,
        .abi = .none,
        .ofmt = .elf,
    };
    const optimize = b.standardOptimizeOption(.{});

    switch (target_arch) {
        .x86_64 => {
            const Feature = std.Target.x86.Feature;

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
        },
        else => unreachable
    }

    // kernel module
    const kernel_mod = b.addModule("kernel", .{
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .red_zone = false,
    });
    
    kernel_mod.code_model = switch (target_arch) {
        .aarch64 => .small,
        .x86_64 => .kernel,
        else => unreachable
    };
    kernel_mod.omit_frame_pointer = false;
    kernel_mod.strip = false;

    // loading dependences
    const SElvaAHCI_module = b.dependency("SElvaAHCI", .{
        .target = target,
        .optimize = optimize,
    }).module("SElvaAHCI_module");
    kernel_mod.addImport("SElvaAHCI_module", SElvaAHCI_module);

    // kernel executable
    const kernel_exe = b.addExecutable(.{
        .name = "kernel",
        .root_module = kernel_mod,
    });
    kernel_exe.entry = .{ .symbol_name = "__boot_entry__" };
    switch (target_arch) {
        .aarch64 => kernel_exe.setLinkerScript(b.path("../_linkage/aarch64.ld")),
        .x86_64 => kernel_exe.setLinkerScript(b.path("../_linkage/x86_64.ld")),
        else => unreachable,
    }

    const install_kernel_step = b.addInstallArtifact(kernel_exe, .{});
    b.getInstallStep().dependOn(&install_kernel_step.step);

}
