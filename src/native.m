#define GLFW_INCLUDE_NONE
#define GLFW_EXPOSE_NATIVE_COCOA
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>

void *zig_glfw_get_cocoa_window(GLFWwindow *window) {
    return glfwGetCocoaWindow(window);
}
