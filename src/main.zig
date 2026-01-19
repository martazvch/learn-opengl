const std = @import("std");
const engine = @import("engine.zig");

// fn customLog(
//     comptime level: std.log.Level,
//     comptime scope: @Type(.enum_literal),
//     comptime format: []const u8,
//     args: anytype,
// ) void {
//     std.log.defaultLog(level, scope, format, args);
//     if (scope == .err) {
//         std.process.exit(1);
//     }
// }
//
// pub const std_options: std.Options = .{
//     // By default, in safe build modes, the standard library will attach a segfault handler to the program to
//     // print a helpful stack trace if a segmentation fault occurs. Here, we can disable this, or even enable
//     // it in unsafe build modes.
//     .enable_segfault_handler = true,
//     // This is the logging function used by `std.log`.
//     .logFn = customLog,
// };

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const allocator, const is_debug = gpa: {
        break :gpa switch (@import("builtin").mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    _ = allocator; // autofix
    defer if (is_debug) {
        std.debug.assert(debug_allocator.deinit() == .ok);
    };

    engine.setupWindow();
}
