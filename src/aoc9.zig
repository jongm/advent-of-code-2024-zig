const std = @import("std");
const testing = std.testing;

const raw = @embedFile("inputs/input9.txt");

pub fn main() void {
    // var gpa = std.heap.DebugAllocator(.{}){};
    // const gpa_allocator = gpa.allocator();
}

test "concat_num" {
    const allocator = testing.allocator;

    const sample = "2333133121414131402";

    var length: u32 = 0;
    for (sample) |char| {
        const char_string = [1]u8{char};
        length += try std.fmt.parseUnsigned(u8, &char_string, 10);
    }
    std.debug.print("LEN {d}\n", .{length});

    var buffer = try allocator.alloc(u16, length);
    defer allocator.free(buffer);
    var mem_id: u16 = 1;
    var pos: u16 = 0;
    var file: bool = true;

    for (sample) |char| {
        const char_string = [1]u8{char};
        const len: u16 = try std.fmt.parseUnsigned(u8, &char_string, 10);
        if (file) {
            for (buffer[pos .. pos + len]) |*cell| {
                cell.* = mem_id;
            }
            mem_id += 1;
        } else {
            for (buffer[pos .. pos + len]) |*cell| {
                cell.* = 0;
            }
        }
        file = !file;
        pos = pos + len;
    }

    std.debug.print("BUFFER: {any}\n", .{buffer});

    // try testing.expect(try concat_num(u64, num1, num2) == 1337);
}
