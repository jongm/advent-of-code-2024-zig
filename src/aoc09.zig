const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input09.txt");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();

    var length: u32 = 0;
    for (raw) |char| {
        if (char == '\n') break;
        const char_string = [1]u8{char};
        length += try std.fmt.parseUnsigned(u8, &char_string, 10);
    }
    // print("LEN {d}\n", .{length});

    var buffer = try allocator.alloc(u32, length);
    defer allocator.free(buffer);

    // Part 1
    try stringToDiskmap(raw, &buffer);
    try compactDiskmap(buffer);
    const res: u64 = sumDiskmap(buffer);
    print("Part 1: {d}\n", .{res});

    // Part 2
    try stringToDiskmap(raw, &buffer);
    try defragDiskmap(buffer, allocator);
    const res2: u64 = sumDiskmap(buffer);
    print("Part 2: {d}\n", .{res2});
    // print("DEFRAG: {any}\n", .{buffer});
}

pub fn stringToDiskmap(string: []const u8, buffer: *[]u32) !void {
    var mem_id: u32 = 1;
    var pos: u32 = 0;
    var file: bool = true;

    for (string) |char| {
        if (char == '\n') break;
        const char_string = [1]u8{char};
        // print("charstring: {any}\n", .{char_string});
        const len: u32 = try std.fmt.parseUnsigned(u8, &char_string, 10);
        if (file) {
            for (buffer.*[pos .. pos + len]) |*cell| {
                cell.* = mem_id;
            }
            mem_id += 1;
        } else {
            for (buffer.*[pos .. pos + len]) |*cell| {
                cell.* = 0;
            }
        }
        file = !file;
        pos = pos + len;
    }
}

pub fn compactDiskmap(buffer: []u32) !void {
    var left: u32 = 0;
    var right: u32 = std.math.cast(u32, buffer.len - 1).?;

    while (right >= 1) : (right -= 1) {
        // print("ROW: {d}, {d}\n", .{ left, right });
        if (left >= right) break;
        if (buffer[right] > 0) {
            for (left..right) |pos| {
                if (pos >= right) break;
                if (buffer[pos] == 0) {
                    buffer[pos] = buffer[right];
                    buffer[right] = 0;
                    left = std.math.cast(u32, pos).?;
                    break;
                }
            }
        }
    }
}

pub fn defragDiskmap(buffer: []u32, allocator: std.mem.Allocator) !void {
    var right: u32 = std.math.cast(u32, buffer.len - 1).?;
    var seen = std.ArrayListUnmanaged(u32).empty;
    defer seen.deinit(allocator);

    mainloop: while (true) {

        // Find right non zero segment
        const start_r = right;
        const current_r: u32 = buffer[right];
        while (true) : (right -= 1) {
            if (buffer[right] != current_r) break;
            if (right <= 0) break :mainloop;
        }
        if (current_r == 0) continue :mainloop;
        for (seen.items) |item| {
            if (current_r == item) continue :mainloop;
        }
        try seen.append(allocator, current_r);

        const len_r: u32 = start_r - right;
        // print("ROW R: Right: {d}, Current: {d}, Len: {d}\n", .{ right, current_r, len_r });

        // Find left zero segment of correct size
        var left: u32 = 0;
        var start_l: u32 = 0;
        while (true) {
            start_l = left;
            const current_l: u32 = buffer[left];
            while (true) {
                // print("ROW L: Left: {d}, Current: {d}, Start: {d}\n", .{ left, current_l, start_l });
                left += 1;
                if (left == buffer.len) continue :mainloop;
                if (buffer[left] != current_l) break;
            }
            const len_l: u32 = left - start_l;
            if ((len_l >= len_r) and (current_l == 0)) break;
        }
        if (left > (right + 1)) continue :mainloop;
        // print("MOVE L: StartL: {d}, LenR: {d}, Right: {d}\n", .{ start_l, len_r, right });
        // Move data from right to left
        for (buffer[start_l .. start_l + len_r]) |*cell| {
            cell.* = current_r;
        }
        for (buffer[right + 1 .. right + 1 + len_r]) |*cell| {
            cell.* = 0;
        }
        // print("FUNC END: {any}\n", .{buffer});
    }
    // print("EXITS MAINLOOP\n", .{});
}

pub fn sumDiskmap(buffer: []u32) u64 {
    var res: u64 = 0;
    for (buffer, 0..) |num, i| {
        if (num == 0) continue;
        const numi: i16 = @intCast(num);
        // print("NUM: {d}, {d}\n", .{ num, i });
        res += i * std.math.cast(u64, (numi - 1)).?;
    }
    return res;
}

test "example_1" {
    const allocator = testing.allocator;

    const sample = "2333133121414131402";

    var length: u32 = 0;
    for (sample) |char| {
        const char_string = [1]u8{char};
        length += try std.fmt.parseUnsigned(u8, &char_string, 10);
    }
    print("LEN {d}\n", .{length});

    var buffer = try allocator.alloc(u32, length);
    defer allocator.free(buffer);

    try stringToDiskmap(sample, &buffer);
    print("BUFFER: {any}\n", .{buffer});

    try compactDiskmap(buffer);
    print("COMPACT: {any}\n", .{buffer});

    const res: u64 = sumDiskmap(buffer);
    print("RESULT: {d}\n", .{res});

    try stringToDiskmap(sample, &buffer);

    try defragDiskmap(buffer, allocator);
    print("DEFRAG: {any}\n", .{buffer});

    const res2: u64 = sumDiskmap(buffer);
    print("RESULT 2: {d}\n", .{res2});

    try testing.expect(res == 1928);
    try testing.expect(res2 == 2858);
}

test "example_2" {
    const allocator = testing.allocator;

    const sample = "0112233";

    var length: u32 = 0;
    for (sample) |char| {
        const char_string = [1]u8{char};
        length += try std.fmt.parseUnsigned(u8, &char_string, 10);
    }
    print("LEN {d}\n", .{length});

    var buffer = try allocator.alloc(u32, length);
    defer allocator.free(buffer);

    try stringToDiskmap(sample, &buffer);
    print("BUFFER: {any}\n", .{buffer});

    try compactDiskmap(buffer);
    print("COMPACT: {any}\n", .{buffer});

    const res: u64 = sumDiskmap(buffer);
    print("RESULT: {d}\n", .{res});

    try stringToDiskmap(sample, &buffer);

    try defragDiskmap(buffer, allocator);
    print("DEFRAG: {any}\n", .{buffer});

    const res2: u64 = sumDiskmap(buffer);
    print("RESULT 2: {d}\n", .{res2});
}
