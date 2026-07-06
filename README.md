# zig-glfw

Small Zig package that builds GLFW from source and exposes a focused Zig wrapper.

The package currently mirrors the GLFW surface needed by `vkmtl` examples:

- window init/teardown
- no-API window creation
- polling and time helpers
- framebuffer extent queries
- raw GLFW/Vulkan interop through the translated `c` module
- Cocoa native window access on macOS

GLFW itself is downloaded through `build.zig.zon`; consumers do not need a
system GLFW install.

Linux builds use GLFW's X11 backend and require the usual X11 system libraries
to be available to Zig's linker.

## Usage

```sh
zig fetch --save git+ssh://git@github.com/HissingRat/zig-glfw.git
```

In `build.zig`:

```zig
const glfw_dep = b.dependency("zig_glfw", .{
    .target = target,
    .optimize = optimize,
});
const glfw = glfw_dep.module("zig_glfw");
const glfw_lib = glfw_dep.artifact("glfw");
```

Import and use the wrapper:

```zig
const glfw = @import("zig_glfw");

try glfw.init();
defer glfw.terminate();

const window = try glfw.createWindow(.{
    .width = 800,
    .height = 600,
    .title = "hello",
});
defer glfw.destroyWindow(window);
```

Link the `glfw` artifact into executables that import `zig_glfw`.

## License

This Zig wrapper is MIT licensed. GLFW is fetched from the upstream GLFW source
package and remains under GLFW's own license.
