const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input06.txt");

pub fn readIntoMatrix(comptime rows: u8, comptime cols: u8, string: []const u8, target: *[rows][cols]u8) void {
    var lines = std.mem.splitScalar(u8, string, '\n');
    var row: u8 = 0;
    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) break;
        target[row] = line[0..cols].*;
    }
}

const directions = [_][2]i16{ [2]i16{ 0, -1 }, [2]i16{ 1, 0 }, [2]i16{ 0, 1 }, [2]i16{ -1, 0 } };

pub fn walkMatrix(comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8, max_loops: u32) bool {
    const pos = std.mem.indexOfScalar(u8, raw, '^').?;
    var col: usize = std.math.cast(usize, pos % @as(usize, cols + 1)).?;
    var row: usize = std.math.cast(usize, pos / @as(usize, rows + 1)).?;
    var dir: u8 = 0;
    std.debug.assert(matrix[row][col] == '^');

    var loops: u16 = 0;

    while (true) : (loops += 1) {
        matrix[row][col] = 'X';
        var newcol: i16 = @intCast(col);
        var newrow: i16 = @intCast(row);

        newcol += directions[dir][0];
        newrow += directions[dir][1];

        const in_map: bool = ((newcol >= 0) and (newcol <= cols - 1) and (newrow <= rows - 1) and (newrow >= 0));
        if (!in_map) break;

        if (matrix[std.math.cast(usize, newrow).?][std.math.cast(usize, newcol).?] == '#') {
            if (dir == 3) {
                dir = 0;
            } else {
                dir += 1;
            }
            continue;
        }

        col = std.math.cast(usize, newcol).?;
        row = std.math.cast(usize, newrow).?;

        if (loops > max_loops) return true;
    }
    return false;
}

pub fn main() !void {
    const rows = 130;
    const cols = 130;
    const max_loops = rows * cols;
    var matrix: [rows][cols]u8 = undefined;

    readIntoMatrix(rows, cols, raw, &matrix);
    _ = walkMatrix(rows, cols, &matrix, max_loops);
    var res: u16 = 0;
    for (matrix) |row| {
        for (row) |cell| {
            if (cell == 'X') {
                res += 1;
            }
        }
    }
    print("Result 1: {d}\n", .{res});

    var res2: u16 = 0;
    for (0..cols) |col| {
        for (0..rows) |row| {
            readIntoMatrix(rows, cols, raw, &matrix);
            if (matrix[row][col] == '.') {
                matrix[row][col] = '#';
                if (walkMatrix(rows, cols, &matrix, max_loops)) {
                    res2 += 1;
                }
            }
        }
    }
    print("Result 2: {d}\n", .{res2});
}
