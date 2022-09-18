const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    std.debug.assert(target.getOsTag() == .linux);

    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("mount.ufs", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addCSourceFile("src/passthrough.c", &.{
        "-DHAVE_UTIMENSAT",
        "-DHAVE_POSIX_FALLOCATE",
        "-DHAVE_SETXATTR",
        "-DHAVE_COPY_FILE_RANGE",
    });
    exe.linkLibC();
    exe.linkSystemLibrary("fuse3");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
