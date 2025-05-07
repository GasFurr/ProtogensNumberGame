const std = @import("std");

/// First thing first - zig build is DECLARATIVE
/// it's not step by step, it declares and works
/// with everything declared, so there's no strict
/// order, and no "instructions", it's just the
/// description of result and not the step-by-step
/// guide.

// Build entry point with Build pointer for mutability.
pub fn build(b: *std.Build) void {

    // Target and optimization. a.k.a. -Dtarget & -Doptimize
    // Target = wow, TARGET ARCHITECTURE & SYSTEM!?!?!?
    const target = b.standardTargetOptions(.{});
    // Optimize = fast, safe, small, etc.
    const optimize = b.standardOptimizeOption(.{});

    // create executable binary target
    const executable = b.addExecutable(.{
        .name = "Guessing Game",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Make target avaliable for installation
    const install = b.addInstallArtifact(executable, .{ .dest_dir = .{ .override = .{ .custom = "../" } } });

    b.default_step.dependOn(&install.step);

    const run_cmd = b.addRunArtifact(executable);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app!");
    run_step.dependOn(&run_cmd.step);
}
