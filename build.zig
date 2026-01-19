const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "learn_opengl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const glfw_dep = b.dependency("glfw_zig", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.linkLibrary(glfw_dep.artifact("glfw"));

    const glad_dep = b.dependency("zig_glad", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.linkLibrary(glad_dep.artifact("glad"));

    const zlm_dep = b.dependency("zlm", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zlm", zlm_dep.module("zlm"));

    exe.root_module.addIncludePath(b.path("src/includes"));
    exe.root_module.addCSourceFile(.{
        .file = b.path("src/includes/stb_image.c"),
    });

    b.installFile("src/assets/wood_container.jpg", "bin/assets/wood_container.jpg");

    b.installArtifact(exe);
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    // --------
    // For ZLS
    // --------
    const exe_check = b.addExecutable(.{
        .name = "foo",
        .root_module = exe.root_module,
    });

    const check = b.step("check", "Check if foo compiles");
    check.dependOn(&exe_check.step);
}
