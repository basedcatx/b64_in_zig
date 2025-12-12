const std = @import("std");
const b64 = @import("struct/b64.zig");

pub fn main() !void {
    const Base64 = b64.Base64.init();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    // const str: []const u8 = "Aello world";
    const estr = "VGVzdGluZyBzb21lIG1vcmUgc2hpdA==";
    const t = try Base64.decode(estr, alloc);
    std.debug.print("{s}\n", .{t});
    for (t) |c| {
        std.debug.print("{d} | ", .{c});
    }
}
