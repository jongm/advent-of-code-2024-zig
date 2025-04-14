const std = @import("std");
const testing = std.testing;

const raw = @embedFile("inputs/input6.txt");

// const raw =
//     \\....#.....
//     \\.........#
//     \\..........
//     \\..#.......
//     \\.......#..
//     \\..........
//     \\.#..^.....
//     \\........#.
//     \\#.........
//     \\......#...
// ;

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

const directions = [_][2]i16{ [2]i16{ 0, -1 }, [2]i16{ 1, 0 }, [2]i16{ 0, 1 }, [2]i16{ -1, 0 } };

const DIMX = 130;
const DIMY = 130;
const MAX_LOOPS = DIMX * DIMY;

pub fn walk_matrix(matrix: anytype) bool {
    const pos = std.mem.indexOfScalar(u8, raw, '^').?;
    var x: usize = std.math.cast(usize, pos % @as(usize, DIMX + 1)).?;
    var y: usize = std.math.cast(usize, pos / @as(usize, DIMY + 1)).?;
    var dir: u8 = 0;
    // std.debug.print("START: {d}, X:{d}, Y:{d}\n", .{ pos, x, y });
    std.debug.assert(matrix.data[y][x] == '^');

    // var seen: [DIMX * DIMY][4]i16 = undefined;
    // var seen_count: u16 = 0;
    var loops: u16 = 0;

    while (true) : (loops += 1) {
        matrix.data[y][x] = 'X';
        var newx: i16 = @intCast(x);
        var newy: i16 = @intCast(y);

        // std.debug.print("SEEN: X{d}, Y:{d}, D1:{d}, D2:{d}\n", .{ x, y, directions[dir][0], directions[dir][1] });
        // seen[seen_count] = [4]i16{ newx, newy, directions[dir][0], directions[dir][1] };
        // seen_count += 1;

        newx += directions[dir][0];
        newy += directions[dir][1];

        const in_map: bool = ((newx >= 0) and (newx <= matrix.width - 1) and (newy <= matrix.height - 1) and (newy >= 0));
        if (!in_map) break;

        if (matrix.data[std.math.cast(usize, newy).?][std.math.cast(usize, newx).?] == '#') {
            if (dir == 3) {
                dir = 0;
            } else {
                dir += 1;
            }
            continue;
        }

        x = std.math.cast(usize, newx).?;
        y = std.math.cast(usize, newy).?;

        if (loops > MAX_LOOPS) return true;

        // const new_seen = [4]i16{ newx, newy, directions[dir][0], directions[dir][1] };

        // for (0..seen_count) |i| {
        //     if (std.mem.eql(i16, &seen[i], &new_seen)) {
        //         return true;
        //     }
        // }

        // std.debug.print("\n\n", .{});
        // for (matrix.data) |row| {
        //     std.debug.print("{s}\n", .{row});
        // }
    }
    return false;
}

pub fn main() !void {
    var matrix = create_matrix_struct(u8, DIMX, DIMY){};

    read_into_matrix(DIMX, DIMY, raw, &matrix.data);
    _ = walk_matrix(&matrix);
    var res: u16 = 0;
    for (matrix.data) |row| {
        for (row) |cell| {
            if (cell == 'X') {
                res += 1;
            }
        }
    }
    std.debug.print("RESULT 1: {d}, ", .{res});

    var res2: u16 = 0;
    for (0..DIMX) |x| {
        for (0..DIMY) |y| {
            read_into_matrix(DIMX, DIMY, raw, &matrix.data);
            if (matrix.data[y][x] == '.') {
                matrix.data[y][x] = '#';
                if (walk_matrix(&matrix)) {
                    res2 += 1;
                }
            }
        }
    }
    std.debug.print("RESULT 2: {d}, ", .{res2});
}
