const c = @import("c.zig");
const gl = c.gl;
const zstbi = @import("zstbi");
const fatal = @import("utils.zig").fatal;

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
    const data = @embedFile(path);

    // OpenGL expects the 0 to be the opposite side
    zstbi.setFlipVerticallyOnLoad(true);
    var image = zstbi.Image.loadFromMemory(data, 0) catch {
        fatal("failed to load image '{s}'", .{path});
    };
    defer image.deinit();

    var tex: u32 = 0;
    gl.glGenTextures(1, &tex);
    gl.glBindTexture(gl.GL_TEXTURE_2D, tex);
    // Second: mimap level
    // Format: rgb
    // the 0 has to always be 0 (legacy stuff)
    // after it's format and data type of source image
    gl.glTexImage2D(
        gl.GL_TEXTURE_2D,
        0,
        fmt.toGLi(),
        @intCast(image.width),
        @intCast(image.height),
        0,
        fmt.toGL(),
        gl.GL_UNSIGNED_BYTE,
        image.data.ptr,
    );
    gl.glGenerateMipmap(gl.GL_TEXTURE_2D);

    return tex;
}
