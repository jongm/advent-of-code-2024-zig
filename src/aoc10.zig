const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input10.txt");

pub fn readIntoMatrix(comptime rows: u8, comptime cols: u8, string: []const u8, target: *[rows][cols]u8) void {
    var lines = std.mem.splitScalar(u8, string, '\n');
    var row: u8 = 0;
    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) break;
        target[row] = line[0..cols].*;
    }
}

pub fn parseMatrixNumss(comptime rows: u8, comptime cols: u8, target: *[rows][cols]u8) !void {
    for (target) |*row| {
        for (row) |*cell| {
            const char_string = [1]u8{cell.*};
            cell.* = try std.fmt.parseUnsigned(u8, &char_string, 10);
        }
    }
}

pub fn exploreDirections(allocator: std.mem.Allocator, res_array: *std.ArrayListUnmanaged([2]usize), comptime rows: u8, comptime cols: u8, matrix: [rows][cols]u8, start_row: usize, start_col: usize, from: ?[2]i16) !u32 {
    const current_num: u8 = matrix[start_row][start_col];
    const col: i16 = @intCast(start_col);
    const row: i16 = @intCast(start_row);
    const next_from = [2]i16{ col, row };
    const directions = [4][2]i16{ .{ col - 1, row }, .{ col + 1, row }, .{ col, row - 1 }, .{ col, row + 1 } };
    var res2: u32 = 0;
    // print("[{d},{d}] - MAIN FUNC , Value: {d}\n", .{ x, y, current_num });
    dirloop: for (directions) |dir| {
        if (from) |f| {
            if (std.mem.eql(i16, &dir, &f)) continue;
        }
        if ((dir[0] >= 0) and (dir[0] < cols) and (dir[1] >= 0) and (dir[1] < rows)) {
            const new_row: usize = std.math.cast(usize, dir[1]).?;
            const new_col: usize = std.math.cast(usize, dir[0]).?;
            const next_num: u8 = matrix[new_row][new_col];
            // print("[{d},{d}] - DIR  Current: {d}, Next: {d} at ({d},{d})\n", .{ x, y, current_num, next_num, new_row, new_col });
            if ((current_num == 8) and (next_num == 9)) {
                res2 += 1;
                const new_res = [2]usize{ new_row, new_col };
                for (res_array.items) |item| {
                    if (std.mem.eql(usize, &item, &new_res)) continue :dirloop;
                }
                try res_array.append(allocator, new_res);
            } else if ((current_num + 1) == next_num) {
                res2 += try exploreDirections(allocator, res_array, rows, cols, matrix, new_row, new_col, next_from);
                // print("[{d},{d}] - NEXT RES: {d}\n", .{ x, y, next_res });
            }
        }
    }
    return res2;
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();

    const rows = 53;
    const cols = 53;
    var matrix: [rows][cols]u8 = undefined;

    readIntoMatrix(rows, cols, raw, &matrix);
    try parseMatrixNumss(rows, cols, &matrix);

    var total: usize = 0;
    var total2: u32 = 0;
    for (0..rows) |row| {
        for (0..cols) |col| {
            if (matrix[row][col] == 0) {
                var res_array: std.ArrayListUnmanaged([2]usize) = .empty;
                defer res_array.deinit(allocator);
                total2 += try exploreDirections(allocator, &res_array, rows, cols, matrix, row, col, null);
                total += res_array.items.len;
            }
        }
    }
    print("RESULT {d}\n", .{total});
    print("RESULT2 {d}\n", .{total2});
}

test "sample" {
    const sample =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;

    const allocator = testing.allocator;
    const rows = 8;
    const cols = 8;

    var matrix: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, sample, &matrix);
    try parseMatrixNumss(rows, cols, &matrix);

    var sample_array: std.ArrayListUnmanaged([2]usize) = .empty;
    defer sample_array.deinit(allocator);
    const res2_1 = try exploreDirections(allocator, &sample_array, rows, cols, matrix, 0, 2, null);
    print("RESULT {d}\n", .{res2_1});

    try testing.expect(sample_array.items.len == 5);
    try testing.expect(res2_1 == 20);

    var total: usize = 0;
    var total2: u32 = 0;
    for (0..rows) |row| {
        for (0..cols) |col| {
            if (matrix[row][col] == 0) {
                var res_array: std.ArrayListUnmanaged([2]usize) = .empty;
                defer res_array.deinit(allocator);
                total2 += try exploreDirections(allocator, &res_array, rows, cols, matrix, row, col, null);
                total += res_array.items.len;
            }
        }
    }
    try testing.expect(total == 36);
    try testing.expect(total2 == 81);
}
