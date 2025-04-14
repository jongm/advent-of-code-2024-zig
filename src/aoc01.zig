const std = @import("std");
const print = std.debug.print;

const input = @embedFile("inputs/input01.txt");

pub fn parseInput(allocator: std.mem.Allocator, string: []const u8, list1: *std.ArrayListUnmanaged(i32), list2: *std.ArrayListUnmanaged(i32)) !void {
    var iterator = std.mem.splitScalar(u8, string, '\n');

    while (iterator.next()) |line| {
        if (line.len == 0) break;
        // print("{s}\n", .{line});
        var nums = std.mem.splitSequence(u8, line, "   ");
        const d1 = nums.next().?;
        const d2 = nums.next().?;

        const d1n = try std.fmt.parseUnsigned(i32, d1, 10);
        const d2n = try std.fmt.parseUnsigned(i32, d2, 10);

        try list1.append(allocator, d1n);
        try list2.append(allocator, d2n);
    }

    // print("{d} - {d}\n", .{ col1.items.len, col2.items.len });
    // print("{any}\n", .{@TypeOf(col1.items)});

    std.mem.sort(i32, list1.items, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, list2.items, {}, comptime std.sort.asc(i32));
}

pub fn isin(comptime T: type, value: T, list: []T) !bool {
    for (list) |el| {
        if (el == value) {
            return true;
        }
    }
    return false;
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();

    var col1: std.ArrayListUnmanaged(i32) = .empty;
    var col2: std.ArrayListUnmanaged(i32) = .empty;
    defer col1.deinit(allocator);
    defer col2.deinit(allocator);

    try parseInput(allocator, input, &col1, &col2);

    var sum: i64 = 0;
    for (col1.items, col2.items) |num1, num2| {
        sum += @abs(num1 - num2);
    }
    print("Results: {d}\n", .{sum});

    var sum2: i64 = 0;
    for (col1.items) |num1| {
        for (col2.items) |num2| {
            if (num1 == num2) {
                sum2 += num1;
            }
        }
    }
    print("Results 2: {d}\n", .{sum2});
}
