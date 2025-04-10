const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input19.txt");

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const allocator = debug_allocator.allocator();

    var input_iterator = std.mem.splitSequence(u8, raw, "\n\n");

    var towel_list: std.ArrayListUnmanaged([]const u8) = .empty;
    defer towel_list.deinit(allocator);
    var iterator = std.mem.splitSequence(u8, input_iterator.next().?, ", ");
    while (iterator.next()) |word| {
        try towel_list.append(allocator, word);
    }

    var res: u64 = 0;

    var sample_iterator = std.mem.splitScalar(u8, input_iterator.next().?, '\n');
    while (sample_iterator.next()) |word| {
        if (word.len == 0) continue;
        const match = matchTowels(word, towel_list.items);
        if (match) res += 1;
    }
    print("Result: {d}\n", .{res});

    var res2: u64 = 0;
    var memo: std.StringHashMapUnmanaged(u64) = .empty;
    defer memo.deinit(allocator);

    sample_iterator.reset();
    while (sample_iterator.next()) |word| {
        if (word.len == 0) continue;
        const match = try matchTowelsAll(allocator, &memo, word, towel_list.items);
        res2 += match;
    }

    print("Result 2: {d}\n", .{res2});
}

pub fn matchTowels(string: []const u8, towels: [][]const u8) bool {
    for (towels) |tow| {
        if (string.len < tow.len) continue;
        if (std.mem.eql(u8, string[0..tow.len], tow)) {
            if (string.len == tow.len) {
                return true;
            } else {
                const next_iter = matchTowels(string[tow.len..], towels);
                if (next_iter == true) return true;
            }
        }
    }
    return false;
}

pub fn matchTowelsAll(allocator: std.mem.Allocator, memo: *std.StringHashMapUnmanaged(u64), string: []const u8, towels: [][]const u8) !u64 {
    var result: u64 = 0;
    for (towels) |tow| {
        if (string.len < tow.len) continue;
        if (std.mem.eql(u8, string[0..tow.len], tow)) {
            if (string.len == tow.len) {
                result += 1;
            } else {
                const substring = string[tow.len..];
                var next_iter: u64 = undefined;
                if (memo.contains(substring)) {
                    next_iter = memo.getPtr(substring).?.*;
                } else {
                    next_iter = try matchTowelsAll(allocator, memo, substring, towels);
                    try memo.put(allocator, substring, next_iter);
                }
                result += next_iter;
            }
        }
    }
    return result;
}
test "sample" {
    const sample =
        \\brwrr
        \\bggr
        \\gbbr
        \\rrbgbr
        \\ubwu
        \\bwurrg
        \\brgr
        \\bbrgwb
    ;
    const towels = "r, wr, b, g, bwu, rb, gb, br";

    const allocator = testing.allocator;

    var towel_list: std.ArrayListUnmanaged([]const u8) = .empty;
    defer towel_list.deinit(allocator);
    var iterator = std.mem.splitSequence(u8, towels, ", ");
    while (iterator.next()) |word| {
        try towel_list.append(allocator, word);
    }

    var res: u8 = 0;

    var sample_iterator = std.mem.splitScalar(u8, sample, '\n');
    while (sample_iterator.next()) |word| {
        if (word.len == 0) continue;
        const match = matchTowels(word, towel_list.items);
        if (match) res += 1;
    }
    print("Sample: {d}\n", .{res});
    try testing.expect(res == 6);

    var res2: u64 = 0;

    var memo: std.StringHashMapUnmanaged(u64) = .empty;
    defer memo.deinit(allocator);
    sample_iterator.reset();
    while (sample_iterator.next()) |word| {
        if (word.len == 0) continue;
        const match = try matchTowelsAll(allocator, &memo, word, towel_list.items);
        res2 += match;
    }

    print("Sample 2: {d}\n", .{res2});
    try testing.expect(res2 == 16);
}
