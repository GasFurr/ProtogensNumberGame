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
        .name = "Game",
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

    // Release package configuration
    const exe_release = b.addExecutable(.{
        .name = "Game",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
    });

    // Create release directory structure
    const mkdir_release = b.addSystemCommand(&.{"mkdir"});
    mkdir_release.addArgs(&.{ "-p", "release" });

    // Install binary to release directory

    const install_release = b.addInstallArtifact(exe_release, .{ .dest_dir = .{ .override = .{ .custom = "../release" } } });

    // Copy resources to release directory
    const copy_resources = b.addSystemCommand(&.{"cp"});
    copy_resources.addArgs(&.{ "-r", "resources/", "release/resources" });

    // Create archive of release directory
    const create_archive = b.addSystemCommand(&.{
        "tar",
        "-czvf",
        "game-release.tar.gz",
        "release",
    });

    // Set up dependencies
    const release_step = b.step("release", "Create release package");
    release_step.dependOn(&mkdir_release.step);
    release_step.dependOn(&install_release.step);
    release_step.dependOn(&copy_resources.step);
    release_step.dependOn(&create_archive.step);

    // Ensure proper execution order
    install_release.step.dependOn(&mkdir_release.step);
    copy_resources.step.dependOn(&mkdir_release.step);
    create_archive.step.dependOn(&install_release.step);
    create_archive.step.dependOn(&copy_resources.step);
}
