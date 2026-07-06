const std = @import("std");
const builtin = @import("builtin");
pub const c = @import("c");

pub const Window = *c.GLFWwindow;
pub const VulkanInstance = c.VkInstance;
pub const VulkanSurface = c.VkSurfaceKHR;
pub const VulkanAllocationCallbacks = c.VkAllocationCallbacks;
pub const VulkanResult = c.VkResult;
pub const VulkanProc = c.GLFWvkproc;

pub const WindowOptions = struct {
    width: u32 = 800,
    height: u32 = 600,
    title: [*:0]const u8,
    resizable: bool = true,
};

pub const Extent2D = struct {
    width: u32,
    height: u32,

    pub fn isZero(self: Extent2D) bool {
        return self.width == 0 or self.height == 0;
    }
};

pub const Error = error{
    InitFailed,
    WindowInitFailed,
};

pub fn init() Error!void {
    if (c.glfwInit() != c.GLFW_TRUE) return Error.InitFailed;
}

pub fn terminate() void {
    c.glfwTerminate();
}

pub fn createWindow(options: WindowOptions) Error!Window {
    c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);
    c.glfwWindowHint(c.GLFW_RESIZABLE, if (options.resizable) c.GLFW_TRUE else c.GLFW_FALSE);
    return c.glfwCreateWindow(
        @intCast(options.width),
        @intCast(options.height),
        options.title,
        null,
        null,
    ) orelse Error.WindowInitFailed;
}

pub fn destroyWindow(window: Window) void {
    c.glfwDestroyWindow(window);
}

pub fn windowShouldClose(window: Window) bool {
    return c.glfwWindowShouldClose(window) != c.GLFW_FALSE;
}

pub fn pollEvents() void {
    c.glfwPollEvents();
}

pub fn timeSeconds() f64 {
    return c.glfwGetTime();
}

pub fn framebufferExtent(window: Window) Extent2D {
    var width: c_int = undefined;
    var height: c_int = undefined;
    c.glfwGetFramebufferSize(window, &width, &height);
    return extentFromFramebufferSize(width, height);
}

pub fn nativeCocoaWindow(window: Window) ?*anyopaque {
    if (comptime builtin.os.tag == .macos) {
        return @ptrCast(c.zig_glfw_get_cocoa_window(window));
    }
    return null;
}

pub fn rawWindow(window: Window) *anyopaque {
    return @ptrCast(window);
}

pub fn getRequiredInstanceExtensions() ?[]const [*:0]const u8 {
    var count: u32 = 0;
    const extensions = c.glfwGetRequiredInstanceExtensions(&count) orelse return null;
    return @ptrCast(extensions[0..count]);
}

pub fn getInstanceProcAddress(instance: VulkanInstance, procname: [*:0]const u8) VulkanProc {
    return c.glfwGetInstanceProcAddress(instance, procname);
}

pub fn createWindowSurface(
    instance: VulkanInstance,
    window: Window,
    allocation_callbacks: ?*const VulkanAllocationCallbacks,
    surface: *VulkanSurface,
) VulkanResult {
    return c.glfwCreateWindowSurface(instance, window, allocation_callbacks, surface);
}

pub fn extentFromFramebufferSize(width: c_int, height: c_int) Extent2D {
    return .{
        .width = @intCast(@max(width, 0)),
        .height = @intCast(@max(height, 0)),
    };
}

test "framebuffer extents clamp negative dimensions" {
    try std.testing.expectEqual(Extent2D{ .width = 0, .height = 16 }, extentFromFramebufferSize(-4, 16));
}

test "window options keep existing defaults" {
    const options = WindowOptions{ .title = "zig-glfw" };
    try std.testing.expectEqual(@as(u32, 800), options.width);
    try std.testing.expectEqual(@as(u32, 600), options.height);
    try std.testing.expect(options.resizable);
}
