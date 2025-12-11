const std = @import("std");
const b64 = @import("struct/b64.zig");

pub fn main() !void {
    const str = "Hello world";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const res = try b64.Base64.init().encode(str, gpa.allocator());
    std.debug.print("{s}", .{res});
    defer gpa.allocator().free(res);
}
