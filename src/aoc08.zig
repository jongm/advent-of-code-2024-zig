const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input08.txt");

pub fn readIntoMatrix(comptime rows: u8, comptime cols: u8, string: []const u8, target: *[rows][cols]u8) void {
    var lines = std.mem.splitScalar(u8, string, '\n');
    var row: u8 = 0;
    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) break;
        target[row] = line[0..cols].*;
    }
}

pub fn calculateNodes(comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8, node1: [2]usize, node2: [2]usize) void {
    const col1: i16 = @intCast(node1[0]);
    const row1: i16 = @intCast(node1[1]);
    const col2: i16 = @intCast(node2[0]);
    const row2: i16 = @intCast(node2[1]);

    const anti1_col: i16 = col1 - col2 + col1;
    const anti1_row: i16 = row1 - row2 + row1;
    const anti2_col: i16 = col2 - col1 + col2;
    const anti2_row: i16 = row2 - row1 + row2;

    if ((anti1_col >= 0) and (anti1_row >= 0) and (anti1_col < cols) and (anti1_row < rows)) {
        matrix[std.math.cast(usize, anti1_row).?][std.math.cast(usize, anti1_col).?] = '*';
    }
    if ((anti2_col >= 0) and (anti2_row >= 0) and (anti2_col < cols) and (anti2_row < rows)) {
        matrix[std.math.cast(usize, anti2_row).?][std.math.cast(usize, anti2_col).?] = '*';
    }
}

pub fn calculateNodesHarmonic(comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8, node1: [2]usize, node2: [2]usize) void {
    const col1: i16 = @intCast(node1[0]);
    const row1: i16 = @intCast(node1[1]);
    const col2: i16 = @intCast(node2[0]);
    const row2: i16 = @intCast(node2[1]);

    // This only works because the nodes coordinates are always from smaller to bigger
    const shift_col: i16 = col2 - col1;
    const shift_row: i16 = row2 - row1;
    // print("SHIFTS: {d}, {d}\n", .{ shift_col, shift_row });

    var jumps: u8 = 0;
    var new_col: i16 = col1 - shift_col;
    var new_row: i16 = row1 - shift_row;
    while ((new_col >= 0) and (new_row >= 0) and (new_col < cols) and (new_row < rows)) {
        jumps += 1;
        new_col -= shift_col;
        new_row -= shift_row;
    }

    var start_col: i16 = col1 - (shift_col * jumps);
    var start_row: i16 = row1 - (shift_row * jumps);

    // print("JUMPS: {d}, {d}, from {d}, {d}, to {d}, {d}\n", .{ jumps_col, jumps_row, col1, row1, start_col, start_row });

    while ((start_col >= 0) and (start_row >= 0) and (start_col < cols) and (start_row < rows)) {
        matrix[std.math.cast(usize, start_row).?][std.math.cast(usize, start_col).?] = '*';
        start_col += shift_col;
        start_row += shift_row;
    }
}

pub fn nodesToMap(data: []const u8, map: *std.AutoHashMapUnmanaged(u8, std.ArrayListUnmanaged([2]usize)), allocator: std.mem.Allocator, rows: u8, cols: u8) !void {
    for (data, 0..) |char, pos| {
        if ((char == '.') or (char == '\n')) continue;
        if (!map.contains(char)) {
            try map.put(allocator, char, std.ArrayListUnmanaged([2]usize).empty);
        }
        // try map.put(char, map.get(char).? + 1);
        var list = map.getPtr(char).?;
        const col: usize = std.math.cast(usize, pos).? % @as(usize, cols + 1);
        const row: usize = std.math.cast(usize, pos).? / @as(usize, rows + 1);
        try list.append(allocator, [2]usize{ col, row });
        // print("TEMP: {any} - {any}\n", .{ char, list.items });
    }
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const gpa_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const rows = 50;
    const cols = 50;

    var map: std.AutoHashMapUnmanaged(u8, std.ArrayListUnmanaged([2]usize)) = .empty;

    try nodesToMap(raw, &map, allocator, rows, cols);

    var matrix: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, raw, &matrix);

    var matrix2: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, raw, &matrix2);

    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        for (0..entry.value_ptr.items.len) |i| {
            for (0..entry.value_ptr.items.len) |j| {
                if (i < j) {
                    _ = calculateNodes(rows, cols, &matrix, entry.value_ptr.items[i], entry.value_ptr.items[j]);
                    _ = calculateNodesHarmonic(rows, cols, &matrix2, entry.value_ptr.items[i], entry.value_ptr.items[j]);
                }
            }
        }
    }

    var res: u16 = 0;
    for (matrix) |row| {
        for (row) |cell| {
            if (cell == '*') {
                res += 1;
            }
        }
    }
    print("Result: {d}\n", .{res});

    var res2: u16 = 0;
    for (matrix2) |row| {
        for (row) |cell| {
            if (cell == '*') {
                res2 += 1;
            }
        }
    }
    print("R2sult2 2: {d}\n", .{res2});
}

test "example" {
    const sample =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;

    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const rows: u8 = 12;
    const cols: u8 = 12;

    var map: std.AutoHashMapUnmanaged(u8, std.ArrayListUnmanaged([2]usize)) = .empty;

    try nodesToMap(sample, &map, allocator, rows, cols);

    var matrix: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, sample, &matrix);

    var matrix2: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, sample, &matrix2);

    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        for (0..entry.value_ptr.items.len) |i| {
            for (0..entry.value_ptr.items.len) |j| {
                if (i < j) {
                    _ = calculateNodes(rows, cols, &matrix, entry.value_ptr.items[i], entry.value_ptr.items[j]);
                    _ = calculateNodesHarmonic(rows, cols, &matrix2, entry.value_ptr.items[i], entry.value_ptr.items[j]);
                }
            }
        }
    }

    var res: u16 = 0;
    for (matrix) |row| {
        for (row) |cell| {
            if (cell == '*') {
                res += 1;
            }
        }
    }
    print("Result: {d}\n", .{res});

    var res2: u16 = 0;
    for (matrix2) |row| {
        for (row) |cell| {
            if (cell == '*') {
                res2 += 1;
            }
        }
    }
    print("Result 2: {d}\n", .{res2});

    try testing.expect(res == 14);
    try testing.expect(res2 == 34);
}
