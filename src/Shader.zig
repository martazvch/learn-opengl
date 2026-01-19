const std = @import("std");
const Allocator = std.mem.Allocator;

const c = @import("c.zig");
const gl = c.gl;
const math = @import("math.zig").math;
const fatal = @import("utils.zig").fatal;

prog: u32,

const Self = @This();

pub fn init(vs_src: [*c]const u8, fs_src: [*c]const u8) Self {
    const vs = compileShader(vs_src, .vertex);
    const fs = compileShader(fs_src, .fragment);
    defer gl.glDeleteShader(vs);
    defer gl.glDeleteShader(fs);

    const prog = gl.glCreateProgram();
    gl.glAttachShader(prog, vs);
    gl.glAttachShader(prog, fs);
    gl.glLinkProgram(prog);

    const BUF_SIZE = 512;
    var info_log: [BUF_SIZE]u8 = undefined;
    var success: c_int = 0;
    gl.glGetProgramiv(prog, gl.GL_LINK_STATUS, &success);

    if (success == 0) {
        gl.glGetShaderInfoLog(prog, 512, null, &info_log);
        fatal("Failed to link shader program:\n{s}", .{info_log});
    }

    return .{
        .prog = prog,
    };
}

fn compileShader(src: [*c]const u8, kind: enum { vertex, fragment }) u32 {
    const shader = gl.glCreateShader(if (kind == .vertex) gl.GL_VERTEX_SHADER else gl.GL_FRAGMENT_SHADER);
    gl.glShaderSource(shader, 1, &[_][*c]const u8{src}, null);
    gl.glCompileShader(shader);

    const BUF_SIZE = 512;
    var info_log: [BUF_SIZE]u8 = undefined;
    var success: c_int = 0;
    gl.glGetShaderiv(shader, gl.GL_COMPILE_STATUS, &success);

    if (success == 0) {
        gl.glGetShaderInfoLog(shader, BUF_SIZE, null, &info_log);
        fatal("Failed to compile fragment shader:\n{s}", .{info_log});
    }

    return shader;
}

pub fn use(self: *const Self) void {
    gl.glUseProgram(self.prog);
}

pub fn setFloat(self: *const Self, name: [*c]const u8, value: f32) void {
    gl.glUniform1f(self.getUniform(name), value);
}

pub fn setInt(self: *const Self, name: [*c]const u8, value: i32) void {
    gl.glUniform1i(self.getUniform(name), value);
}

pub fn setMat4f(self: *const Self, name: [*c]const u8, value: math.Mat4) void {
    // Second arg is the number of matrices and the third one is if we don't use column-major ordering
    gl.glUniformMatrix4fv(self.getUniform(name), 1, gl.GL_FALSE, @ptrCast(&value.fields));
}

fn getUniform(self: *const Self, name: [*c]const u8) i32 {
    const loc = gl.glGetUniformLocation(self.prog, name);

    if (loc == -1) {
        fatal("can't fetch uniform name: {s}", .{name});
    }

    return loc;
}
