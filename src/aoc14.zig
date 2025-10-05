const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input14.txt");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();

    const cols = 101;
    const rows = 103;

    var robots: std.ArrayListUnmanaged([4]i32) = .empty;
    defer robots.deinit(allocator);
    try parseRobots(allocator, raw, &robots);

    var matrix: [rows][cols]i32 = @splat([_]i32{0} ** cols);
    for (robots.items) |item| {
        const pos_x: usize = @intCast(item[0]);
        const pos_y: usize = @intCast(item[1]);
        matrix[pos_y][pos_x] += 1;
    }

    // hojas 25, tronco 62
    var res: i32 = undefined;

    // const start: usize = 1530;
    // for (0..start) |_| {
    //     waitSecond(cols, rows, &matrix, robots.items);
    // }

    var i: usize = 1;
    while (true) : (i += 1) {
        waitSecond(cols, rows, &matrix, robots.items);
        if (i == 100) {
            res = countCuadrants(cols, rows, &matrix);
            print("Part 1: {d}\n", .{res});
        }

        // This means that probabbly the tree is there:
        const to_check: bool = checkForTree(cols, rows, &matrix, 20);

        if (to_check) {
            // print("x1B[2J\x1B[H\n", .{});
            print("Part 2: {d}\n", .{i});
            //// These lines below plot the tree
            // for (matrix) |row| {
            //     for (row) |cell| {
            //         if (cell == 0) {
            //             print(" ", .{});
            //         } else {
            //             print("{d}", .{cell});
            //         }
            //     }
            //     print("\n", .{});
            // }
            // print("\nEND ITERATION - {d}\n", .{i});

            // const stdin = std.io.getStdIn();
            // var buffer = [_]u8{ 0, 0 };
            // _ = try stdin.reader().readUntilDelimiter(&buffer, '\n');
            // std.time.sleep(1000 * 1000 * 500);
            break;
        }
    }
}

pub fn checkForTree(comptime cols: usize, comptime rows: usize, matrix: *[rows][cols]i32, thresh: u8) bool {
    for (matrix) |row| {
        var accum: u8 = 0;
        for (row) |cell| {
            if (cell > 0) {
                accum += 1;
            } else {
                accum = 0;
            }
            if (accum >= thresh) return true;
        }
    }
    return false;
}

pub fn parseRobots(allocator: std.mem.Allocator, string: []const u8, array: *std.ArrayListUnmanaged([4]i32)) !void {
    var row_iterator = std.mem.splitScalar(u8, string, '\n');
    while (row_iterator.next()) |row| {
        if (row.len == 0) break;
        var data_iterator = std.mem.splitScalar(u8, row, '=');
        _ = data_iterator.first();
        const pos = std.mem.trim(u8, data_iterator.next().?, " v");
        const speed = std.mem.trim(u8, data_iterator.next().?, " ");
        const pos_middle = std.mem.indexOf(u8, pos, ",").?;
        const speed_middle = std.mem.indexOf(u8, speed, ",").?;

        const pos_x: i32 = try std.fmt.parseInt(i32, pos[0..pos_middle], 10);
        const pos_y: i32 = try std.fmt.parseInt(i32, pos[pos_middle + 1 ..], 10);
        const speed_x: i32 = try std.fmt.parseInt(i32, speed[0..speed_middle], 10);
        const speed_y: i32 = try std.fmt.parseInt(i32, speed[speed_middle + 1 ..], 10);

        const robot = [4]i32{ pos_x, pos_y, speed_x, speed_y };
        try array.append(allocator, robot);
    }
}

pub fn waitSecond(comptime cols: usize, comptime rows: usize, matrix: *[rows][cols]i32, robots: [][4]i32) void {
    for (robots) |*item| {
        const cols_i: i32 = @intCast(cols);
        const rows_i: i32 = @intCast(rows);

        const pos_x: usize = @intCast(item[0]);
        const pos_y: usize = @intCast(item[1]);

        var new_x_int = item[0] + item[2];
        if (new_x_int < 0) new_x_int += cols_i;
        if (new_x_int >= cols_i) new_x_int -= cols_i;
        var new_y_int = item[1] + item[3];
        if (new_y_int < 0) new_y_int += rows_i;
        if (new_y_int >= rows_i) new_y_int -= rows_i;

        const new_x: usize = @intCast(new_x_int);
        const new_y: usize = @intCast(new_y_int);

        matrix[pos_y][pos_x] -= 1;
        matrix[new_y][new_x] += 1;

        item.*[0] = new_x_int;
        item.*[1] = new_y_int;
    }
}

pub fn countCuadrants(comptime cols: usize, comptime rows: usize, matrix: *[rows][cols]i32) i32 {
    const mid_x: usize = cols / 2 + 1;
    const mid_y: usize = rows / 2 + 1;

    var cuadrants: [4]i32 = @splat(0);
    var robots: i32 = 0;
    for (matrix, 1..) |row, y| {
        for (row, 1..) |cell, x| {
            if (cell > 0) robots += cell;
            if ((x < mid_x) and (y < mid_y)) cuadrants[0] += cell;
            if ((x > mid_x) and (y < mid_y)) cuadrants[1] += cell;
            if ((x < mid_x) and (y > mid_y)) cuadrants[2] += cell;
            if ((x > mid_x) and (y > mid_y)) cuadrants[3] += cell;
        }
    }
    // print("CUADRANTS: {any}\n", .{cuadrants});
    // print("ROBOTS: {d}\n", .{robots});
    // print("IN CUAD: {d}\n", .{cuadrants[0] + cuadrants[1] + cuadrants[2] + cuadrants[3]});

    const total: i32 = cuadrants[0] * cuadrants[1] * cuadrants[2] * cuadrants[3];
    return total;
}

test "sample" {
    const allocator = testing.allocator;

    const cols = 11;
    const rows = 7;

    const sample =
        \\p=0,4 v=3,-3
        \\p=6,3 v=-1,-3
        \\p=10,3 v=-1,2
        \\p=2,0 v=2,-1
        \\p=0,0 v=1,3
        \\p=3,0 v=-2,-2
        \\p=7,6 v=-1,-3
        \\p=3,0 v=-1,-2
        \\p=9,3 v=2,3
        \\p=7,3 v=-1,2
        \\p=2,4 v=2,-3
        \\p=9,5 v=-3,-3
    ;

    var robots: std.ArrayListUnmanaged([4]i32) = .empty;
    defer robots.deinit(allocator);
    try parseRobots(allocator, sample, &robots);
    // for (robots.items) |item| {
    //     print("{any}\n", .{item});
    // }

    var matrix: [rows][cols]i32 = @splat([_]i32{0} ** cols);
    for (robots.items) |item| {
        const pos_x: usize = @intCast(item[0]);
        const pos_y: usize = @intCast(item[1]);
        matrix[pos_y][pos_x] += 1;
    }

    print("\nSTART\n", .{});
    for (matrix) |row| {
        for (row) |cell| {
            if (cell == 0) {
                print(".", .{});
            } else {
                print("{d}", .{cell});
            }
        }
        print("\n", .{});
    }

    for (0..100) |_| {
        waitSecond(cols, rows, &matrix, robots.items);
    }
    print("\nEND\n", .{});
    for (matrix) |row| {
        for (row) |cell| {
            if (cell == 0) {
                print(".", .{});
            } else {
                print("{d}", .{cell});
            }
        }
        print("\n", .{});
    }

    const res = countCuadrants(cols, rows, &matrix);
    try testing.expect(res == 12);
}
