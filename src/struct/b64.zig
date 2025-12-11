const std = @import("std");

pub const Base64 = struct {
    _table: *const [64]u8,
    _ignored_char: u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numb = "0123456789+/";
        return Base64{ ._table = upper ++ lower ++ numb, ._ignored_char = 61 };
    }

    pub fn char_at(self: Base64, index: usize) !u8 {
        if (index < 0 or index > 63)
            @panic("Invalid index please specify an index between 0 and 63 inclusive");
        return self._table[index];
    }

    pub fn calc_encode_length(self: Base64, input: []const u8) !usize {
        _ = self;
        if (input.len < 4) return 4;
        const res: usize = try std.math.divCeil(usize, input.len, 3);
        return res * 4;
    }

    pub fn calc_decode_length(self: Base64, b64_input: []const u8) !usize {
        _ = self;
        if (b64_input.len < 4) return 3;
        const res: usize = try std.math.divFloor(usize, b64_input.len, 4) * 3;
        return res;
    }

    pub fn encode(self: Base64, input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
        const length = try self.calc_encode_length(input);
        const out_buffer = try alloc.alloc(u8, length);
        var focus: [3]u8 = [3]u8{ 0, 0, 0 };
        var count: usize = 0;
        var offset: usize = 0;

        for (input, 0..) |_, i| {
            focus[count] = input[i];
            count += 1;

            if (count == 3) {
                out_buffer[offset] = try self.char_at(focus[0] >> 2);
                offset += 1;
                out_buffer[offset] = try self.char_at(((focus[0] & 0x03) << 4) + (focus[1] >> 4));
                offset += 1;
                out_buffer[offset] = try self.char_at(((focus[1] & 0x0f) << 2) + (focus[2] >> 6));
                offset += 1;
                out_buffer[offset] = try self.char_at(focus[2] & 0x3f);
                offset += 1;
                count = 0;
            }
        }

        if (count == 2) {
            out_buffer[offset] = try self.char_at(focus[0] >> 2);
            offset += 1;
            out_buffer[offset] = try self.char_at(((focus[0] & 0x03) << 4) + focus[1] >> 4);
            offset += 1;
            out_buffer[offset] = try self.char_at((focus[1] & 0x0f) << 2);
            offset += 1;
            out_buffer[offset] = self._ignored_char;
        }

        if (count == 1) {
            out_buffer[offset] = try self.char_at(focus[0] >> 2);
            offset += 1;
            out_buffer[offset] = try self.char_at((focus[0] & 0x03) << 4);
            offset += 1;
            out_buffer[offset] = self._ignored_char;
            offset += 1;
            out_buffer[offset] = self._ignored_char;
            offset += 1;
        }

        return out_buffer;
    }
};
