const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input07.txt");

const Ops = enum { sum, mul, conc };

pub fn main() !void {
    var buffer: [16]u64 = undefined;

    const ops1 = [_]Ops{ Ops.sum, Ops.mul };
    var rows_iter = std.mem.splitScalar(u8, raw, '\n');
    var res: u64 = 0;
    while (rows_iter.next()) |row| {
        if (row.len == 0) break;
        res += try checkLine(&buffer, row, &ops1);
    }
    print("Part 1: {d}\n", .{res});

    const ops2 = [_]Ops{ Ops.sum, Ops.mul, Ops.conc };
    rows_iter.reset();
    var res2: u64 = 0;
    while (rows_iter.next()) |row| {
        if (row.len == 0) break;
        res2 += try checkLine(&buffer, row, &ops2);
    }
    print("Part 2: {d}\n", .{res2});
}

pub fn findDigits(num: u64) u64 {
    var digits: u64 = 1;
    while (num >= std.math.pow(u64, 10, digits)) {
        digits += 1;
    }
    return digits;
}

pub fn checkLine(buffer: []u64, line: []const u8, comptime ops: []const Ops) !u64 {
    var row_iter = std.mem.splitSequence(u8, line, ":");
    const target: u64 = try std.fmt.parseUnsigned(u64, row_iter.next().?, 10);

    const numbers_str: []const u8 = std.mem.trim(u8, row_iter.next().?, " ");

    var nums_iter = std.mem.splitScalar(u8, numbers_str, ' ');

    var pos: usize = 0;
    while (nums_iter.next()) |num| : (pos += 1) {
        buffer[pos] = try std.fmt.parseUnsigned(u64, num, 10);
    }

    if (try doNextOperation(target, buffer[0], buffer[1..pos], ops)) {
        return target;
    } else {
        return 0;
    }
}

pub fn concatNum(comptime T: type, num1: T, num2: T) T {
    const final: u64 = num1 * std.math.pow(u64, 10, findDigits(num2)) + num2;
    return final;
}

pub fn doNextOperation(target: u64, current: u64, nums: []u64, comptime ops: []const Ops) !bool {
    const next = nums[0];
    var final: [ops.len]bool = undefined;

    for (ops, 0..) |op, i| {
        var result = current;
        // std.debug.print("Target {}, current {}, nums {any}, op {any}, res {}\n", .{ target, current, nums, op, result });
        switch (op) {
            Ops.sum => result += next,
            Ops.mul => result *= next,
            Ops.conc => {
                result = concatNum(u64, result, next);
            },
        }

        if (nums.len == 1) {
            final[i] = result == target;
        } else {
            final[i] = try doNextOperation(target, result, nums[1..], ops);
        }
    }
    return for (final) |f| {
        if (f == true) {
            break true;
        }
    } else false;
}

test "findDigits" {
    try testing.expect(findDigits(8) == 1);
    try testing.expect(findDigits(34) == 2);
    try testing.expect(findDigits(999) == 3);
    try testing.expect(findDigits(12345678) == 8);
}

test "concatNum" {
    try testing.expect(concatNum(u64, 8, 4) == 84);
    try testing.expect(concatNum(u64, 20, 5) == 205);
    try testing.expect(concatNum(u64, 345, 678) == 345678);
    try testing.expect(concatNum(u64, 8945, 4) == 89454);
}

test "doNextOperation" {
    const ops1 = [_]Ops{ Ops.sum, Ops.mul };
    var sample1 = [_]u64{ 81, 40, 27 };
    try testing.expect(try doNextOperation(3267, sample1[0], sample1[1..], &ops1));
    var sample2 = [_]u64{ 6, 8, 6, 15 };
    try testing.expect(!try doNextOperation(7290, sample1[0], sample2[1..], &ops1));
}

test "checkLines" {
    var buffer: [16]u64 = undefined;
    const ops1 = [_]Ops{ Ops.sum, Ops.mul };
    const sample1 = "190: 10 19";
    try testing.expect(try checkLine(&buffer, sample1, &ops1) == 190);
    const sample2 = "3267: 81 40 27";
    try testing.expect(try checkLine(&buffer, sample2, &ops1) == 3267);

    const sample3 = "83: 17 5";
    try testing.expect(try checkLine(&buffer, sample3, &ops1) == 0);
    const sample4 = "156: 15 6";
    try testing.expect(try checkLine(&buffer, sample4, &ops1) == 0);
    const sample5 = "7290: 6 8 6 15";
    try testing.expect(try checkLine(&buffer, sample5, &ops1) == 0);
    const sample6 = "161011: 16 10 13";
    try testing.expect(try checkLine(&buffer, sample6, &ops1) == 0);
    const sample7 = "192: 17 8 14";
    try testing.expect(try checkLine(&buffer, sample7, &ops1) == 0);
    const sample8 = "21037: 9 7 18 13";
    try testing.expect(try checkLine(&buffer, sample8, &ops1) == 0);
    const sample9 = "292: 11 6 16 20";
    try testing.expect(try checkLine(&buffer, sample9, &ops1) == 292);
}
