const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input11.txt");

pub fn loadStones(allocator: std.mem.Allocator, map: *std.AutoHashMapUnmanaged(u64, u64), string: []const u8) !void {
    var iterator = std.mem.splitScalar(u8, string, ' ');
    while (iterator.next()) |num| {
        const nump: u64 = try std.fmt.parseInt(u64, std.mem.trimRight(u8, num, "\n"), 10);
        if (map.contains(nump)) {
            map.getPtr(nump).?.* += 1;
        } else {
            try map.put(allocator, nump, 1);
        }
    }
    if (!map.contains(0)) try map.put(allocator, 0, 0);
    if (!map.contains(1)) try map.put(allocator, 1, 0);
}

pub fn blink(allocator: std.mem.Allocator, stones: *std.AutoHashMapUnmanaged(u64, u64)) !void {
    var clone = try stones.clone(allocator);
    defer clone.deinit(allocator);
    var iterator = clone.iterator();

    while (iterator.next()) |entry| {
        const stone = entry.key_ptr.*;
        const count = entry.value_ptr.*;
        if (count == 0) continue;
        const stone_string = try std.fmt.allocPrint(allocator, "{d}", .{stone});
        defer allocator.free(stone_string);
        stones.getPtr(stone).?.* -= 1 * count;
        if (stone == 0) {
            stones.getPtr(1).?.* += 1 * count;
        } else if ((stone_string.len % 2) == 0) {
            const middle: usize = stone_string.len / 2;
            const new_1: u64 = try std.fmt.parseInt(u64, stone_string[0..middle], 10);
            const new_2: u64 = try std.fmt.parseInt(u64, stone_string[middle..], 10);
            if (!stones.contains(new_1)) try stones.put(allocator, new_1, 0);
            if (!stones.contains(new_2)) try stones.put(allocator, new_2, 0);
            stones.getPtr(new_1).?.* += 1 * count;
            stones.getPtr(new_2).?.* += 1 * count;
        } else {
            const new_num: u64 = stone * 2024;
            if (!stones.contains(new_num)) try stones.put(allocator, new_num, 0);
            stones.getPtr(new_num).?.* += 1 * count;
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();

    const n1 = 25;
    const n2 = 75;

    var stones: std.AutoHashMapUnmanaged(u64, u64) = .empty;
    defer stones.deinit(allocator);

    try loadStones(allocator, &stones, raw);

    var res: u64 = 0;
    for (0..n1) |_| {
        // print("I: {d}\n", .{i + 1});
        try blink(allocator, &stones);
    }
    var iterator = stones.iterator();
    while (iterator.next()) |entry| {
        res += entry.value_ptr.*;
    }
    print("Result: {d}\n", .{res});

    var stones2: std.AutoHashMapUnmanaged(u64, u64) = .empty;
    defer stones2.deinit(allocator);

    try loadStones(allocator, &stones2, raw);
    var res2: u64 = 0;
    for (0..n2) |_| {
        // print("I: {d}\n", .{i + 1});
        try blink(allocator, &stones2);
    }
    var iterator2 = stones2.iterator();
    while (iterator2.next()) |entry| {
        res2 += entry.value_ptr.*;
    }
    print("Result 2: {d}\n", .{res2});
}

test "sample" {
    const allocator = testing.allocator;
    const n = 6;

    const sample = "125 17";

    var stones: std.AutoHashMapUnmanaged(u64, u64) = .empty;
    defer stones.deinit(allocator);

    try loadStones(allocator, &stones, sample);

    for (0..n) |_| {
        // print("ITERATION: {d}\n", .{i + 1});
        try blink(allocator, &stones);
        // var iterator = stones.iterator();
        // while (iterator.next()) |entry| {
        //     if (entry.value_ptr.* == 0) continue;
        //     print("MAP: {d}, {d}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        // }
    }
    var res: u64 = 0;
    var iterator = stones.iterator();
    while (iterator.next()) |entry| {
        // print("MAP: {d} {d}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        res += entry.value_ptr.*;
    }
    try testing.expect(res == 22);
}
