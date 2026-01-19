pub const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub const gl = @cImport({
    @cInclude("glad/glad.h");
});

pub const stbi = @cImport({
    @cInclude("stb_image.h");
});
