const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input05.txt");

pub fn orderPage(items: []u8, rules: [][2]u8, buffer: []u8) void {
    var safe: u8 = 0;
    for (items, 0..) |item, i| {
        buffer[i] = item;
    }
    while (!checkPage(buffer, rules)) : (safe += 1) {
        if (safe > 10) {
            print("Error after iterations\n", .{});
            break;
        }
        for (rules) |rule| {
            // print("Buffer: {any}, Rule: {any}\n", .{ buffer, rule });
            const pos1 = getPosition(buffer, rule[0]);
            const pos2 = getPosition(buffer, rule[1]);
            if ((pos1 == null) or (pos2 == null)) {
                continue;
            }
            if (pos1.? < pos2.?) {
                continue;
            } else {
                buffer[pos1.?] = rule[1];
                buffer[pos2.?] = rule[0];
            }
        }
    }
}

test "orderPage" {
    var items = [_]u8{ 75, 53, 61, 47 };
    var rules = [_][2]u8{ [_]u8{ 47, 75 }, [_]u8{ 61, 75 }, [_]u8{ 61, 47 }, [_]u8{ 75, 53 } };
    var ordered: [4]u8 = undefined;
    orderPage(&items, &rules, &ordered);
    try testing.expect(checkPage(&ordered, &rules));
}

pub fn getPosition(items: []u8, num: u8) ?u8 {
    var ix: u8 = 0;
    for (items) |item| {
        if (item == num) {
            return ix;
        } else {
            ix += 1;
        }
    }
    return null;
}

test "getPosition" {
    var items = [_]u8{ 5, 10, 15, 20 };
    const pos1 = getPosition(items[0..], 15);
    const pos2 = getPosition(items[0..], 99);
    try testing.expect(pos1 == 2);
    try testing.expect(pos2 == null);
}

pub fn checkPage(items: []u8, rules: [][2]u8) bool {
    for (rules) |rule| {
        const pos1 = getPosition(items, rule[0]);
        const pos2 = getPosition(items, rule[1]);
        if ((pos1 == null) or (pos2 == null)) {
            continue;
        }
        if (pos1.? < pos2.?) {
            continue;
        } else {
            return false;
        }
    }
    return true;
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();

    var parts = std.mem.splitSequence(u8, raw, "\n\n");

    // RULES
    var rules: std.ArrayListUnmanaged([2]u8) = .empty;
    defer rules.deinit(allocator);
    var rules_iter = std.mem.splitSequence(u8, parts.next().?, "\n");

    while (rules_iter.next()) |row| {
        // print("ROW: {any} \n", .{row});
        var new_rule: [2]u8 = undefined;
        var row_iter = std.mem.splitSequence(u8, row, "|");
        var ix: u8 = 0;
        while (row_iter.next()) |num| : (ix += 1) {
            // print("NUM: {any} \n", .{num});
            new_rule[ix] = try std.fmt.parseUnsigned(u8, num, 10);
        }
        // print("RULE: {any} \n", .{new_rule});
        try rules.append(allocator, new_rule);
    }

    // PAGES
    var pages_iter = std.mem.splitSequence(u8, parts.next().?, "\n");
    var sum_ok: u16 = 0;
    var sum_not: u16 = 0;
    while (pages_iter.next()) |row| {
        if (row.len == 0) {
            break;
        }
        var page: std.ArrayListUnmanaged(u8) = .empty;
        defer page.deinit(allocator);
        var row_iter = std.mem.splitSequence(u8, row, ",");
        while (row_iter.next()) |num| {
            // print("NUM: {any} \n", .{num});
            const nump = try std.fmt.parseUnsigned(u8, num, 10);
            try page.append(allocator, nump);
        }
        // print("PAGE: {any} \n", .{page.items});
        const page_ok = checkPage(page.items, rules.items);
        if (page_ok) {
            const middle: u8 = std.math.cast(u8, page.items.len).? / 2;
            sum_ok += page.items[middle];
        } else {
            const buffer = try allocator.alloc(u8, page.items.len);
            defer allocator.free(buffer);
            orderPage(page.items, rules.items, buffer);
            const middle: u8 = std.math.cast(u8, page.items.len).? / 2;
            sum_not += buffer[middle];
        }
    }

    print("RESULT: \nPart 1: {d}\nPart 2: {d}", .{ sum_ok, sum_not });
}
