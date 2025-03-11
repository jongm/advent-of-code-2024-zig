const std = @import("std");
const testing = std.testing;

const raw = @embedFile("inputs/input10.txt");

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

pub fn parse_matrix_nums(comptime w: u8, comptime h: u8, target: *[w][h]u8) !void {
    for (target) |*row| {
        for (row) |*cell| {
            const char_string = [1]u8{cell.*};
            cell.* = try std.fmt.parseUnsigned(u8, &char_string, 10);
        }
    }
}

pub fn explore_directions(allocator: std.mem.Allocator, res_array: *std.ArrayListUnmanaged([2]usize), matrix: anytype, x: usize, y: usize, from: ?[2]i16) !u32 {
    const current_num: u8 = matrix.data[y][x];
    const xi: i16 = @intCast(x);
    const yi: i16 = @intCast(y);
    const next_from = [2]i16{ xi, yi };
    const directions = [4][2]i16{ [2]i16{ xi - 1, yi }, [2]i16{ xi + 1, yi }, [2]i16{ xi, yi - 1 }, [2]i16{ xi, yi + 1 } };
    var res2: u32 = 0;
    // std.debug.print("[{d},{d}] - MAIN FUNC , Value: {d}\n", .{ x, y, current_num });
    dirloop: for (directions) |dir| {
        if (from) |f| {
            if (std.mem.eql(i16, &dir, &f)) continue;
        }
        if ((dir[0] >= 0) and (dir[0] < matrix.width) and (dir[1] >= 0) and (dir[1] < matrix.height)) {
            const new_x: usize = std.math.cast(usize, dir[0]).?;
            const new_y: usize = std.math.cast(usize, dir[1]).?;
            const next_num: u8 = matrix.data[new_y][new_x];
            // std.debug.print("[{d},{d}] - DIR  Current: {d}, Next: {d} at ({d},{d})\n", .{ x, y, current_num, next_num, new_x, new_y });
            if ((current_num == 8) and (next_num == 9)) {
                res2 += 1;
                const new_res = [2]usize{ new_x, new_y };
                for (res_array.items) |item| {
                    if (std.mem.eql(usize, &item, &new_res)) continue :dirloop;
                }
                try res_array.append(allocator, new_res);
            } else if ((current_num + 1) == next_num) {
                res2 += try explore_directions(allocator, res_array, matrix, new_x, new_y, next_from);
                // std.debug.print("[{d},{d}] - NEXT RES: {d}\n", .{ x, y, next_res });
            }
        }
    }
    return res2;
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    const dimX = 53;
    const dimY = 53;
    var matrix = create_matrix_struct(u8, dimX, dimY){};
    read_into_matrix(dimX, dimY, raw, &matrix.data);
    try parse_matrix_nums(dimX, dimY, &matrix.data);

    var total: usize = 0;
    var total2: u32 = 0;
    for (0..dimX) |x| {
        for (0..dimY) |y| {
            if (matrix.data[y][x] == 0) {
                var res_array: std.ArrayListUnmanaged([2]usize) = .empty;
                defer res_array.deinit(allocator);
                total2 += try explore_directions(allocator, &res_array, matrix, x, y, null);
                total += res_array.items.len;
            }
        }
    }
    std.debug.print("RESULT {d}\n", .{total});
    std.debug.print("RESULT2 {d}\n", .{total2});
}

test "sample" {
    const allocator = testing.allocator;
    const testX = 8;
    const testY = 8;
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

    var matrix = create_matrix_struct(u8, testX, testY){};
    read_into_matrix(testX, testY, sample, &matrix.data);
    try parse_matrix_nums(testX, testY, &matrix.data);

    var sample_array: std.ArrayListUnmanaged([2]usize) = .empty;
    defer sample_array.deinit(allocator);
    const res2_1 = try explore_directions(allocator, &sample_array, matrix, 2, 0, null);
    std.debug.print("RESULT {d}\n", .{res2_1});

    try testing.expect(sample_array.items.len == 5);
    try testing.expect(res2_1 == 20);

    var total: usize = 0;
    var total2: u32 = 0;
    for (0..testX) |x| {
        for (0..testY) |y| {
            if (matrix.data[y][x] == 0) {
                var res_array: std.ArrayListUnmanaged([2]usize) = .empty;
                defer res_array.deinit(allocator);
                total2 += try explore_directions(allocator, &res_array, matrix, x, y, null);
                total += res_array.items.len;
            }
        }
    }
    try testing.expect(total == 36);
    try testing.expect(total2 == 81);
}
