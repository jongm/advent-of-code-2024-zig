const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input07.txt");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();

    const power = 2;
    var rows_iter = std.mem.splitScalar(u8, raw, '\n');
    var res: u64 = 0;
    while (rows_iter.next()) |row| {
        if (row.len == 0) break;
        res += try checkLine(allocator, row, power);
    }
    print("Part 1: {d}\n", .{res});

    const power2 = 3;
    rows_iter.reset();
    var res2: u64 = 0;
    while (rows_iter.next()) |row| {
        if (row.len == 0) break;
        res2 += try checkLine(allocator, row, power2);
    }
    print("Part 2: {d}\n", .{res2});
}

pub fn checkLine(allocator: std.mem.Allocator, line: []const u8, power: u8) !u64 {
    var row_iter = std.mem.splitSequence(u8, line, ":");
    const target: u64 = try std.fmt.parseUnsigned(u64, row_iter.next().?, 10);

    const numbers_str: []const u8 = std.mem.trim(u8, row_iter.next().?, " ");

    var nums_iter = std.mem.splitScalar(u8, numbers_str, ' ');
    var numbers: std.ArrayListUnmanaged(u64) = .empty;
    defer numbers.deinit(allocator);

    while (nums_iter.next()) |num| {
        const nump = try std.fmt.parseUnsigned(u64, num, 10);
        try numbers.append(allocator, nump);
    }

    if (try checkOperators(target, numbers.items, power)) {
        return target;
    } else {
        return 0;
    }
}

pub fn concatNum(comptime T: type, num1: T, num2: T) !T {
    var buf: [24]u8 = undefined;
    const numAsString = try std.fmt.bufPrint(&buf, "{d}{d}", .{ num1, num2 });
    const final = try std.fmt.parseUnsigned(T, numAsString, 10);
    return final;
}

pub fn checkOperators(target: u64, nums: []u64, power: u8) !bool {
    // print("TARGET: {d}, NUMS: {d}\n", .{ target, nums });
    for (0..std.math.pow(usize, power, nums.len - 1)) |i| {
        var start = nums[0];
        for (nums[1..], 0..) |new, n| {
            const operation: usize = (i / std.math.pow(usize, power, n)) % power;
            // print("i: {d}, n: {d}, op: {d}\n", .{ i, n, operation });
            switch (operation) {
                0 => start += new,
                1 => start *= new,
                2 => {
                    start = try concatNum(u64, start, new);
                },
                else => unreachable,
            }
        }
        if (start == target) return true;
    }
    return false;
}

test "concatNum" {
    const num1: u64 = 13;
    const num2: u64 = 37;
    try testing.expect(try concatNum(u64, num1, num2) == 1337);
}

test "checkOperators" {
    var sample1 = [_]u64{ 81, 40, 27 };
    try testing.expect(try checkOperators(3267, &sample1, 2));
    var sample2 = [_]u64{ 6, 8, 6, 15 };
    try testing.expect(!try checkOperators(7290, &sample2, 2));
}

test "checkLines" {
    const allocator = testing.allocator;
    const sample1 = "190: 10 19";
    try testing.expect(try checkLine(allocator, sample1, 2) == 190);
    const sample2 = "3267: 81 40 27";
    try testing.expect(try checkLine(allocator, sample2, 2) == 3267);

    const sample3 = "83: 17 5";
    try testing.expect(try checkLine(allocator, sample3, 2) == 0);
    const sample4 = "156: 15 6";
    try testing.expect(try checkLine(allocator, sample4, 2) == 0);
    const sample5 = "7290: 6 8 6 15";
    try testing.expect(try checkLine(allocator, sample5, 2) == 0);
    const sample6 = "161011: 16 10 13";
    try testing.expect(try checkLine(allocator, sample6, 2) == 0);
    const sample7 = "192: 17 8 14";
    try testing.expect(try checkLine(allocator, sample7, 2) == 0);
    const sample8 = "21037: 9 7 18 13";
    try testing.expect(try checkLine(allocator, sample8, 2) == 0);
    const sample9 = "292: 11 6 16 20";
    try testing.expect(try checkLine(allocator, sample9, 2) == 292);
}
