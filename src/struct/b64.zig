const std = @import("std");

pub const Base64 = struct {
    _table: *const [64]u8,
    _ignored_char_in_ascii: u8,
    _ignored_char_in_b64: u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numb = "0123456789+/";
        return Base64{ ._table = upper ++ lower ++ numb, ._ignored_char_in_ascii = 61, ._ignored_char_in_b64 = 64 };
    }

    pub fn char_at(self: Base64, index: usize) !u8 {
        if (index < 0 or index > 63)
            @panic("Invalid index please specify an index between 0 and 63 inclusive");
        return self._table[index];
    }

    pub fn char_index(self: Base64, char: u8) !u8 {
        if (char == '=') return 64;
        var index: u8 = 0;
        for (0..63) |i| {
            if (try self.char_at(i) == char) break;
            index += 1;
        }
        return index;
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
        const res: usize = try std.math.divFloor(usize, b64_input.len, 4) * 3; // We use the divFloor because every encoded b64 string is bound to be a multiple of 4. If for instance it gets corrupted, we take the least multiple of 4s we can find, effectively discarding the fractional part as per the encoding format
        return res;
    }

    pub fn encode(self: Base64, input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
        const out_buffer = try alloc.alloc(u8, try self.calc_encode_length(input));
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

    pub fn decode(self: Base64, encoded_input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
        const out_buffer = try alloc.alloc(u8, try self.calc_decode_length(encoded_input));
        const buf = try alloc.alloc(u8, encoded_input.len);
        defer alloc.free(buf);

        var focus = [4]u8{ 0, 0, 0, 0 };
        var offset: usize = 0;
        var count: u8 = 0;
        std.mem.copyForwards(u8, buf, "0");

        for (0..encoded_input.len) |i| {
            buf[i] = try self.char_index(encoded_input[i]);
        }

        for (buf) |b| {
            focus[count] = b;
            count += 1;

            if (count == 4) {
                out_buffer[offset] = (focus[0] << 2) + (focus[1] >> 4);
                offset += 1;

                if (focus[2] != self._ignored_char_in_b64) {
                    out_buffer[offset] = (focus[1] << 4) + (focus[2] >> 2);
                    offset += 1;
                }

                if (focus[3] != self._ignored_char_in_b64) {
                    out_buffer[offset] = (focus[2] << 6) + (focus[3]);
                    offset += 1;
                }
                count = 0;
            }
        }

        return out_buffer;
    }
};
