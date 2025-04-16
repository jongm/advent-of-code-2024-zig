const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input25.txt");

pub fn parseLocksAndKeys(allocator: std.mem.Allocator, string: []const u8, locks: *std.ArrayListUnmanaged([5]u8), keys: *std.ArrayListUnmanaged([5]u8)) !void {
    var iterator = std.mem.splitSequence(u8, string, "\n\n");
    while (iterator.next()) |block| {
        var new_element: [5]u8 = @splat(0);
        for (block[6..35], 0..) |char, i| {
            if (char == '#') {
                const pos = i % 6;
                new_element[pos] += 1;
            }
        }
        if (block[0] == '#') {
            try locks.append(allocator, new_element);
        } else {
            try keys.append(allocator, new_element);
        }
    }
}

pub fn matchLocksAndKeys(locks: *std.ArrayListUnmanaged([5]u8), keys: *std.ArrayListUnmanaged([5]u8)) u32 {
    var res: u32 = 0;
    for (locks.items) |lock| {
        keyloop: for (keys.items) |key| {
            for (0..5) |i| {
                const sum = lock[i] + key[i];
                if (sum > 5) continue :keyloop;
            }
            res += 1;
        }
    }
    return res;
}

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    const allocator = debug_allocator.allocator();

    var lock_list = std.ArrayListUnmanaged([5]u8).empty;
    defer lock_list.deinit(allocator);
    var key_list = std.ArrayListUnmanaged([5]u8).empty;
    defer key_list.deinit(allocator);

    try parseLocksAndKeys(allocator, raw, &lock_list, &key_list);

    const res = matchLocksAndKeys(&lock_list, &key_list);

    print("Result {d}\n", .{res});
}

test "sample" {
    const sample =
        \\#####
        \\.####
        \\.####
        \\.####
        \\.#.#.
        \\.#...
        \\.....
        \\
        \\#####
        \\##.##
        \\.#.##
        \\...##
        \\...#.
        \\...#.
        \\.....
        \\
        \\.....
        \\#....
        \\#....
        \\#...#
        \\#.#.#
        \\#.###
        \\#####
        \\
        \\.....
        \\.....
        \\#.#..
        \\###..
        \\###.#
        \\###.#
        \\#####
        \\
        \\.....
        \\.....
        \\.....
        \\#....
        \\#.#..
        \\#.#.#
        \\#####
    ;

    const allocator = testing.allocator;

    var lock_list = std.ArrayListUnmanaged([5]u8).empty;
    defer lock_list.deinit(allocator);
    var key_list = std.ArrayListUnmanaged([5]u8).empty;
    defer key_list.deinit(allocator);

    try parseLocksAndKeys(allocator, sample, &lock_list, &key_list);

    for (lock_list.items) |item| {
        print("Lock: {d}\n", .{item});
    }
    for (key_list.items) |item| {
        print("Key: {d}\n", .{item});
    }

    const res = matchLocksAndKeys(&lock_list, &key_list);
    print("Result {d}\n", .{res});

    try testing.expect(res == 3);
}
