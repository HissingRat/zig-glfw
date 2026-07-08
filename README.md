# zig-glfw

Small Zig package that builds GLFW from source and exposes a focused Zig wrapper.

The package currently mirrors the GLFW surface needed by `vkmtl` examples:

- window init/teardown
- no-API window creation
- polling and time helpers
- framebuffer extent queries
- Vulkan interop helpers from GLFW
- Cocoa native window access on macOS
- Windows builds through GLFW's Win32 backend

GLFW itself is downloaded through `build.zig.zon`; consumers do not need a
system GLFW install.

Linux builds use GLFW's X11 backend and require the usual X11 system libraries
to be available to Zig's linker.
Windows builds use GLFW's Win32 backend and can be cross-compiled with Zig,
for example `zig build -Dtarget=x86_64-windows-gnu`.
MSVC targets may require a local Windows SDK so Zig can find system import
libraries such as `gdi32`.

## Usage

```sh
zig fetch --save git+https://github.com/HissingRat/zig-glfw.git
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

## Vulkan And Native Interop

GLFW owns Vulkan surface creation for GLFW windows, so this wrapper exposes the
same interop points:

```zig
const extensions = glfw.getRequiredInstanceExtensions();
const proc = glfw.getInstanceProcAddress(instance, "vkCreateInstance");
const result = glfw.createWindowSurface(instance, window, null, &surface);
```

The wrapper intentionally does not depend on `vulkan-zig`; it uses the Vulkan C
types surfaced by GLFW's translated header. Consumers can cast those handles to
their own Vulkan binding types at their API boundary.

Graphics libraries that keep GLFW outside their core can build their own
provider/adapter from these functions. The intended boundary is:

- `getRequiredInstanceExtensions()` supplies the instance extensions.
- `getInstanceProcAddress(...)` supplies Vulkan loader entry points.
- `createWindowSurface(...)` creates the window surface for an existing Vulkan
  instance.

For Metal, GLFW does not provide a Metal surface API. On macOS this wrapper only
exposes `nativeCocoaWindow(window)`, which is enough for a graphics library to
attach or create a `CAMetalLayer`.

OpenGL context helpers are not wrapped yet because this package currently
targets no-API windows and Vulkan/Metal interop.

## License

This Zig wrapper is MIT licensed. GLFW is fetched from the upstream GLFW source
package and remains under GLFW's own license.
