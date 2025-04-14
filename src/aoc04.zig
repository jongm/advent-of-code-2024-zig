const std = @import("std");
const testing = std.testing;

// var gpa = std.heap.GeneralPurposeAllocator(.{}){};
// const allocator = gpa.allocator();

const raw = @embedFile("inputs/input4.txt");

pub fn create_matrix_struct(comptime T: type, width: u32, height: u32) type {
    return struct { data: [width][height]T = undefined, width: u32 = width, height: u32 = height };
}

pub fn read_into_matrix(comptime w: u8, comptime h: u8, string: []const u8, target: *[w][h]u8) void {
    var lines = std.mem.splitSequence(u8, string, "\n");
    var row: u8 = 0;
    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) {
            break;
        }
        target[row] = line[0..w].*;
    }
}

const directions = [_][2]i16{ [2]i16{ -1, 0 }, [2]i16{ -1, 1 }, [2]i16{ 0, 1 }, [2]i16{ 1, 1 }, [2]i16{ 1, 0 }, [2]i16{ 1, -1 }, [2]i16{ 0, -1 }, [2]i16{ -1, -1 } };

const crosses = [_][4]i16{ [4]i16{ -1, 1, 1, -1 }, [4]i16{ -1, -1, 1, 1 }, [4]i16{ 1, 1, -1, -1 }, [4]i16{ 1, -1, -1, 1 } };

pub fn explore_direction(target: anytype, dir: [2]i16, x: usize, y: usize) bool {
    const objectives = "MAS";
    var newx: i16 = @intCast(x);
    var newy: i16 = @intCast(y);
    var obj: u8 = 0;
    newx += dir[0];
    newy += dir[1];
    main: while ((newx >= 0) and (newx <= target.width - 1) and (newy <= target.height - 1) and (newy >= 0)) {
        const xcord = std.math.cast(usize, newx).?;
        const ycord = std.math.cast(usize, newy).?;
        // std.debug.print("xcord: {d} ycord: {d}\n", .{ xcord, ycord });
        if (target.data[xcord][ycord] == objectives[obj]) {
            if (obj == 2) {
                return true;
            } else {
                obj += 1;
                newx += dir[0];
                newy += dir[1];
                continue :main;
            }
        } else {
            break;
        }
    }
    return false;
}

pub fn explore_cross(target: anytype, dir: [4]i16, x: usize, y: usize) bool {
    var newx1: i16 = @intCast(x);
    var newy1: i16 = @intCast(y);
    var newx2: i16 = @intCast(x);
    var newy2: i16 = @intCast(y);

    newx1 += dir[0];
    newy1 += dir[1];
    newx2 += dir[2];
    newy2 += dir[3];

    if ((newx1 < 0) or (newx1 > target.width - 1) or (newy1 < 0) or (newy1 > target.height - 1) or (newx2 < 0) or (newx2 > target.width - 1) or (newy2 < 0) or (newy2 > target.height - 1)) {
        return false;
    }

    const xcord1 = std.math.cast(usize, newx1).?;
    const ycord1 = std.math.cast(usize, newy1).?;
    const xcord2 = std.math.cast(usize, newx2).?;
    const ycord2 = std.math.cast(usize, newy2).?;

    if ((target.data[xcord1][ycord1] == 'M') and (target.data[xcord2][ycord2] == 'S')) {
        return true;
    } else {
        return false;
    }
}

pub fn count_xmas(target: anytype) u32 {
    var sum: u32 = 0;
    for (0..target.width) |x| {
        for (0..target.height) |y| {
            if (target.data[x][y] == 'X') {
                for (directions) |dir| {
                    // std.debug.print("CORDS: {d} {d}, DIR {any}\n", .{ x, y, dir });
                    if (explore_direction(target, dir, x, y)) {
                        sum += 1;
                        // std.debug.print("Found XMAS above \n", .{});
                    }
                }
            }
        }
    }
    return sum;
}

pub fn count_xmas_2(target: anytype) u32 {
    var sum: u32 = 0;
    for (0..target.width) |x| {
        for (0..target.height) |y| {
            if (target.data[x][y] == 'A') {
                var cross_count: u8 = 0;
                for (crosses) |cro| {
                    // std.debug.print("CORDS: {d} {d}, DIR {any}\n", .{ x, y, dir });
                    if (explore_cross(target, cro, x, y)) {
                        cross_count += 1;
                        // std.debug.print("Found XMAS above \n", .{});
                    }
                }
                if (cross_count >= 2) {
                    sum += 1;
                    // std.debug.print("Found XMAS above \n", .{});
                }
            }
        }
    }
    return sum;
}

// const Matrix140 = create_matrix_struct(u8, 140, 140);

// var matrix = create_matrix_struct(u8, 140, 140){};

pub fn main() !void {
    var matrix = create_matrix_struct(u8, 140, 140){};
    read_into_matrix(140, 140, raw, &matrix.data);
    const res = count_xmas(matrix);
    std.debug.print("RESULT: {d}, ", .{res});

    const res2 = count_xmas_2(matrix);
    std.debug.print("RESULT 2: {d}", .{res2});
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
    var matrixtest = create_matrix_struct(u8, 10, 10){};
    read_into_matrix(10, 10, sample, &matrixtest.data);
    const res = count_xmas(matrixtest);

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
    var matrixtest = create_matrix_struct(u8, 10, 10){};
    read_into_matrix(10, 10, sample, &matrixtest.data);
    const res = count_xmas_2(matrixtest);

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
    var matrixtest = create_matrix_struct(u8, 9, 9){};
    read_into_matrix(9, 9, sample, &matrixtest.data);
    const res = explore_direction(matrixtest, [2]i16{ 0, -1 }, 1, 4);
    try testing.expect(res);
}
