const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input04.txt");

pub fn readIntoMatrix(comptime rows: u8, comptime cols: u8, string: []const u8, target: *[rows][cols]u8) void {
    var lines = std.mem.splitScalar(u8, string, '\n');
    var row: u8 = 0;
    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) break;
        target[row] = line[0..cols].*;
    }
}

const directions = [_][2]i16{ .{ -1, 0 }, .{ -1, 1 }, .{ 0, 1 }, .{ 1, 1 }, .{ 1, 0 }, .{ 1, -1 }, .{ 0, -1 }, .{ -1, -1 } };

const crosses = [_][4]i16{ .{ -1, 1, 1, -1 }, .{ -1, -1, 1, 1 }, .{ 1, 1, -1, -1 }, .{ 1, -1, -1, 1 } };

pub fn exploreDirection(comptime rows: u8, comptime cols: u8, target: [rows][cols]u8, dir: [2]i16, row: usize, col: usize) bool {
    const objectives = "MAS";
    var newcol: i16 = @intCast(col);
    var newrow: i16 = @intCast(row);
    var obj: u8 = 0;
    newcol += dir[0];
    newrow += dir[1];
    main: while ((newcol >= 0) and (newcol <= cols - 1) and (newrow <= rows - 1) and (newrow >= 0)) {
        const colcord = std.math.cast(usize, newcol).?;
        const rowcord = std.math.cast(usize, newrow).?;
        // print("xcord: {d} ycord: {d}\n", .{ xcord, ycord });
        if (target[rowcord][colcord] == objectives[obj]) {
            if (obj == 2) {
                return true;
            } else {
                obj += 1;
                newcol += dir[0];
                newrow += dir[1];
                continue :main;
            }
        } else {
            break;
        }
    }
    return false;
}

pub fn exploreCross(comptime rows: u8, comptime cols: u8, target: [rows][cols]u8, dir: [4]i16, row: usize, col: usize) bool {
    var newcol1: i16 = @intCast(col);
    var newrow1: i16 = @intCast(row);
    var newcol2: i16 = @intCast(col);
    var newrow2: i16 = @intCast(row);

    newcol1 += dir[0];
    newrow1 += dir[1];
    newcol2 += dir[2];
    newrow2 += dir[3];

    if ((newcol1 < 0) or (newcol1 > cols - 1) or (newrow1 < 0) or (newrow1 > rows - 1) or (newcol2 < 0) or (newcol2 > cols - 1) or (newrow2 < 0) or (newrow2 > rows - 1)) {
        return false;
    }

    const colcord1 = std.math.cast(usize, newcol1).?;
    const rowcord1 = std.math.cast(usize, newrow1).?;
    const colcord2 = std.math.cast(usize, newcol2).?;
    const rowcord2 = std.math.cast(usize, newrow2).?;

    if ((target[rowcord1][colcord1] == 'M') and (target[rowcord2][colcord2] == 'S')) {
        return true;
    } else {
        return false;
    }
}

pub fn countXmas(comptime rows: u8, comptime cols: u8, target: [rows][cols]u8) u32 {
    var sum: u32 = 0;
    for (0..rows) |row| {
        for (0..cols) |col| {
            if (target[row][col] == 'X') {
                for (directions) |dir| {
                    // print("CORDS: {d} {d}, DIR {any}\n", .{ x, y, dir });
                    if (exploreDirection(rows, cols, target, dir, row, col)) {
                        sum += 1;
                        // print("Found XMAS above \n", .{});
                    }
                }
            }
        }
    }
    return sum;
}

pub fn countXmasPartTwo(comptime rows: u8, comptime cols: u8, target: [rows][cols]u8) u32 {
    var sum: u32 = 0;
    for (0..rows) |row| {
        for (0..cols) |col| {
            if (target[row][col] == 'A') {
                var cross_count: u8 = 0;
                for (crosses) |cro| {
                    // print("CORDS: {d} {d}, DIR {any}\n", .{ x, y, dir });
                    if (exploreCross(rows, cols, target, cro, row, col)) {
                        cross_count += 1;
                        // print("Found XMAS above \n", .{});
                    }
                }
                if (cross_count >= 2) {
                    sum += 1;
                    // print("Found XMAS above \n", .{});
                }
            }
        }
    }
    return sum;
}

pub fn main() !void {
    const rows: u8 = 140;
    const cols: u8 = 140;

    var matrix: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, raw, &matrix);

    const res = countXmas(rows, cols, matrix);
    print("Part 1: {d}\n", .{res});

    const res2 = countXmasPartTwo(rows, cols, matrix);
    print("Part 2: {d}\n", .{res2});
}

test "example" {
    const sample =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;
    const rows: u8 = 10;
    const cols: u8 = 10;
    var matrixtest: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, sample, &matrixtest);
    const res = countXmas(rows, cols, matrixtest);

    try testing.expect(res == 18);
}

test "example2" {
    const sample =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;
    const rows: u8 = 10;
    const cols: u8 = 10;
    var matrixtest: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, sample, &matrixtest);
    const res = countXmasPartTwo(rows, cols, matrixtest);

    try testing.expect(res == 9);
}

test "explore" {
    const sample =
        \\MMMSXXMAS
        \\MSAMXMSMS
        \\AMXSXMAAM
        \\MSAMASMSM
        \\XMASAMXAM
        \\XXAMMXXAM
        \\SMSMSASXS
        \\SAXAMASAA
        \\MAMMMXMMM
    ;
    const rows: u8 = 9;
    const cols: u8 = 9;
    var matrixtest: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, sample, &matrixtest);
    const res = exploreDirection(rows, cols, matrixtest, [2]i16{ -1, 0 }, 1, 4);
    try testing.expect(res);
}
