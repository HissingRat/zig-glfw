const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const glfw_dep = b.dependency("glfw", .{});
    const vulkan_headers = b.dependency("vulkan_headers", .{});

    const c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
    });
    c.addSystemIncludePath(glfw_dep.path("include"));
    c.addSystemIncludePath(vulkan_headers.path("include"));
    const c_module = c.createModule();

    const module = b.addModule("zig_glfw", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "c", .module = c_module },
        },
    });

    const lib = addGlfw(b, target, optimize, glfw_dep, vulkan_headers);
    b.installArtifact(lib);

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "c", .module = c_module },
            },
        }),
    });
    tests.root_module.linkLibrary(lib);
    const run_tests = b.addRunArtifact(tests);

    const basic = b.addExecutable(.{
        .name = "zig-glfw-basic",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/basic/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "zig_glfw", .module = module },
            },
        }),
    });
    basic.root_module.linkLibrary(lib);
    b.installArtifact(basic);

    const run_basic = b.addRunArtifact(basic);
    if (b.args) |args| run_basic.addArgs(args);

    const test_step = b.step("test", "Run zig-glfw tests");
    test_step.dependOn(&run_tests.step);

    const run_step = b.step("run", "Run the basic GLFW example");
    run_step.dependOn(&run_basic.step);
}

fn addGlfw(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    glfw_dep: *std.Build.Dependency,
    vulkan_headers: *std.Build.Dependency,
) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "glfw",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    lib.root_module.addIncludePath(glfw_dep.path("include"));
    lib.root_module.addIncludePath(glfw_dep.path("src"));
    lib.root_module.addIncludePath(vulkan_headers.path("include"));

    const common_sources = &.{
        "context.c",
        "init.c",
        "input.c",
        "monitor.c",
        "null_init.c",
        "null_joystick.c",
        "null_monitor.c",
        "null_window.c",
        "platform.c",
        "vulkan.c",
        "window.c",
        "egl_context.c",
        "osmesa_context.c",
    };
    const common_flags = &.{
        "-std=c99",
        "-Wno-deprecated-declarations",
    };
    lib.root_module.addCSourceFiles(.{
        .root = glfw_dep.path("src"),
        .files = common_sources,
        .flags = common_flags,
    });

    switch (target.result.os.tag) {
        .macos => {
            lib.root_module.addCMacro("_GLFW_COCOA", "1");
            lib.root_module.addCSourceFile(.{
                .file = b.path("src/native.m"),
                .flags = &.{"-Wno-deprecated-declarations"},
            });
            lib.root_module.addCSourceFiles(.{
                .root = glfw_dep.path("src"),
                .files = &.{
                    "cocoa_init.m",
                    "cocoa_joystick.m",
                    "cocoa_monitor.m",
                    "cocoa_time.c",
                    "cocoa_window.m",
                    "nsgl_context.m",
                    "posix_module.c",
                    "posix_thread.c",
                },
                .flags = common_flags,
            });
        },
        .linux => {
            lib.root_module.addCMacro("_GLFW_X11", "1");
            lib.root_module.addCSourceFiles(.{
                .root = glfw_dep.path("src"),
                .files = &.{
                    "glx_context.c",
                    "linux_joystick.c",
                    "posix_module.c",
                    "posix_poll.c",
                    "posix_thread.c",
                    "posix_time.c",
                    "x11_init.c",
                    "x11_monitor.c",
                    "x11_window.c",
                    "xkb_unicode.c",
                },
                .flags = common_flags,
            });
        },
        .windows => {
            lib.root_module.addCMacro("_GLFW_WIN32", "1");
            lib.root_module.addCSourceFiles(.{
                .root = glfw_dep.path("src"),
                .files = &.{
                    "wgl_context.c",
                    "win32_init.c",
                    "win32_joystick.c",
                    "win32_module.c",
                    "win32_monitor.c",
                    "win32_thread.c",
                    "win32_time.c",
                    "win32_window.c",
                },
                .flags = common_flags,
            });
        },
        else => @panic("zig-glfw currently wires GLFW for macOS, Linux, and Windows only."),
    }

    linkPlatformLibraries(lib.root_module, target.result.os.tag);
    return lib;
}

fn linkPlatformLibraries(module: *std.Build.Module, os_tag: std.Target.Os.Tag) void {
    switch (os_tag) {
        .macos => {
            module.linkFramework("Cocoa", .{});
            module.linkFramework("CoreFoundation", .{});
            module.linkFramework("IOKit", .{});
            module.linkFramework("QuartzCore", .{});
        },
        .linux => {
            module.linkSystemLibrary("X11", .{});
            module.linkSystemLibrary("Xcursor", .{});
            module.linkSystemLibrary("Xi", .{});
            module.linkSystemLibrary("Xinerama", .{});
            module.linkSystemLibrary("Xrandr", .{});
            module.linkSystemLibrary("dl", .{});
            module.linkSystemLibrary("m", .{});
            module.linkSystemLibrary("pthread", .{});
        },
        .windows => {
            module.linkSystemLibrary("gdi32", .{});
        },
        else => {},
    }
}
