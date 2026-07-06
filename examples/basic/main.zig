const glfw = @import("zig_glfw");

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    const window = try glfw.createWindow(.{
        .width = 640,
        .height = 360,
        .title = "zig-glfw basic",
    });
    defer glfw.destroyWindow(window);

    const start = glfw.timeSeconds();
    while (!glfw.windowShouldClose(window) and glfw.timeSeconds() - start < 2.0) {
        glfw.pollEvents();
    }
}
