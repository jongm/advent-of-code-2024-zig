const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input22.txt");

pub fn evolveSecret(num: u64) u64 {
    var mult: u64 = num * 64;
    var mix: u64 = mult ^ num;
    var pruned: u64 = mix % 16777216;
    mult = pruned / 32;
    mix = pruned ^ mult;
    pruned = mix % 16777216;
    mult = pruned * 2048;
    mix = mult ^ pruned;
    pruned = mix % 16777216;
    return pruned;
}

test "evolving" {
    try testing.expect(evolveSecret(@as(u64, 123)) == 15887950);
    try testing.expect(evolveSecret(@as(u64, 15887950)) == 16495136);
    try testing.expect(evolveSecret(@as(u64, 16495136)) == 527345);
    try testing.expect(evolveSecret(@as(u64, 527345)) == 704524);
}

pub fn calculatePriceChanges(allocator: std.mem.Allocator, secret: u64, prices_list: *std.ArrayListUnmanaged([2000]u8), changes_list: *std.ArrayListUnmanaged([2000]i16)) !void {
    var changes: [2000]i16 = undefined;
    var prices: [2000]u8 = undefined;
    var prev: u8 = @intCast(secret % 10);
    var current: u64 = secret;
    for (0..2000) |i| {
        current = evolveSecret(current);
        prices[i] = @intCast(current % 10);
        changes[i] = try std.math.sub(i16, prices[i], prev);
        prev = prices[i];
    }
    try changes_list.append(allocator, changes);
    try prices_list.append(allocator, prices);
}

pub fn calculateBananas(sequence: [4]i16, prices_list: *std.ArrayListUnmanaged([2000]u8), changes_list: *std.ArrayListUnmanaged([2000]i16)) u32 {
    var sum: u32 = 0;
    var counter: u8 = 0;
    for (changes_list.items, prices_list.items) |changes, prices| {
        for (changes, 0..) |change, i| {
            if (change == sequence[counter]) {
                counter += 1;
            } else {
                counter = 0;
            }
            if (counter == 4) {
                sum += prices[i];
                //print("Price: {d}\n", .{prices[i]});
                counter = 0;
                break;
            }
        }
    }
    return sum;
}

pub fn main() !void {
    var res: u64 = 0;
    var iterator = std.mem.splitScalar(u8, raw, '\n');

    while (iterator.next()) |num| {
        if (num.len == 0) break;
        const secret = try std.fmt.parseInt(u64, num, 10);
        var current: u64 = secret;
        for (0..2000) |_| {
            current = evolveSecret(current);
        }
        res += current;
        //print("Seed: {d}, final {d}\n", .{ secret, current });
    }

    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    const allocator = debug_allocator.allocator();

    var changes_list: std.ArrayListUnmanaged([2000]i16) = .empty;
    defer changes_list.deinit(allocator);
    var prices_list: std.ArrayListUnmanaged([2000]u8) = .empty;
    defer prices_list.deinit(allocator);
    print("Part 1: {d}\n", .{res});

    // Part 2
    iterator.reset();
    while (iterator.next()) |num| {
        if (num.len == 0) break;
        const secret = try std.fmt.parseInt(u64, num, 10);
        try calculatePriceChanges(allocator, secret, &prices_list, &changes_list);
    }

    var banana_map: std.AutoArrayHashMapUnmanaged([4]i16, u32) = .empty;
    defer banana_map.deinit(allocator);
    var seen_map: std.AutoHashMapUnmanaged([4]i16, u32) = .empty;
    defer seen_map.deinit(allocator);

    for (changes_list.items, prices_list.items) |changes, prices| {
        for (3..changes.len) |i| {
            const change_seq: [4]i16 = .{ changes[i], changes[i - 1], changes[i - 2], changes[i - 3] };
            if (!seen_map.contains(change_seq)) {
                try (seen_map.put(allocator, change_seq, 0));
                if (banana_map.contains(change_seq)) {
                    banana_map.getPtr(change_seq).?.* += prices[i];
                } else {
                    try banana_map.put(allocator, change_seq, prices[i]);
                }
            }
        }
        seen_map.clearRetainingCapacity();
    }
    var banana_iterator = banana_map.iterator();
    var res2: u32 = 0;
    while (banana_iterator.next()) |entry| {
        const new_val = entry.value_ptr.*;
        if (new_val > res2) res2 = new_val;
    }

    print("Part 2: {d}\n", .{res2});
}

test "sample" {
    const sample = [_]u64{ 1, 10, 100, 2024 };

    var res: u64 = 0;
    for (sample) |secret| {
        var current: u64 = secret;
        for (0..2000) |_| {
            current = evolveSecret(current);
        }
        res += current;
        print("Seed: {d}, final {d}\n", .{ secret, current });
    }
    print("Sample: {d}\n", .{res});
    try testing.expect(res == 37327623);
}

test "sample part 2" {
    const allocator = testing.allocator;
    const sample = [_]u64{ 1, 2, 3, 2024 };

    var changes_list: std.ArrayListUnmanaged([2000]i16) = .empty;
    defer changes_list.deinit(allocator);
    var prices_list: std.ArrayListUnmanaged([2000]u8) = .empty;
    defer prices_list.deinit(allocator);

    for (sample) |secret| {
        try calculatePriceChanges(allocator, secret, &prices_list, &changes_list);
    }

    const bananas = calculateBananas([4]i16{ -2, 1, -1, 3 }, &prices_list, &changes_list);
    print("Bananas {d}\n", .{bananas});
    try testing.expect(bananas == 23);
}
