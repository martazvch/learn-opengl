const c = @import("c.zig");
const gl = c.gl;
const stbi = c.stbi;

pub const Format = enum {
    rgb,
    rgba,

    pub fn toGL(self: Format) u32 {
        return switch (self) {
            .rgb => gl.GL_RGB,
            .rgba => gl.GL_RGBA,
        };
    }

    pub fn toGLi(self: Format) i32 {
        return @intCast(self.toGL());
    }
};

pub fn create(comptime path: []const u8, fmt: Format) u32 {
    var width: i32 = 0;
    var height: i32 = 0;
    var nr_channels: i32 = 0;
    const data = @embedFile(path);

    // OpenGL expects the 0 to be the opposite side
    stbi.stbi_set_flip_vertically_on_load(@intFromBool(true));
    const tex_data = stbi.stbi_load_from_memory(data, data.len, &width, &height, &nr_channels, 0);
    // const tex_data = stbi.stbi_load("assets/wood_container.jpg", &width, &height, &nr_channels, 0);

    var tex: u32 = 0;
    gl.glGenTextures(1, &tex);
    gl.glBindTexture(gl.GL_TEXTURE_2D, tex);
    // Second: mimap level
    // Format: rgb
    // the 0 has to always be 0 (legacy stuff)
    // after it's format and data type of source image
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, fmt.toGLi(), width, height, 0, fmt.toGL(), gl.GL_UNSIGNED_BYTE, tex_data);
    gl.glGenerateMipmap(gl.GL_TEXTURE_2D);
    stbi.stbi_image_free(tex_data);

    return tex;
}
