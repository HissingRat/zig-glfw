#define GLFW_INCLUDE_NONE
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>

#if defined(__APPLE__)
void *zig_glfw_get_cocoa_window(GLFWwindow *window);
#endif
