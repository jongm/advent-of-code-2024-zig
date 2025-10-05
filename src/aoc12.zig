const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input12.txt");

pub fn readIntoMatrix(comptime rows: u8, comptime cols: u8, string: []const u8, target: *[rows][cols]u8) void {
    var lines = std.mem.splitScalar(u8, string, '\n');
    var row: u8 = 0;
    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) break;
        target[row] = line[0..cols].*;
    }
}

pub fn explorePlot(allocator: std.mem.Allocator, array: *std.ArrayListUnmanaged(std.ArrayListUnmanaged([2]u8)), comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8, coords: [2]u8, index: ?u16) !void {

    // Add to list if its the same letter
    var key: u16 = undefined;
    if (index == null) {
        key = @intCast(array.items.len);
        try array.*.append(allocator, std.ArrayListUnmanaged([2]u8).empty);
        try array.*.items[key].append(allocator, coords);
    } else {
        key = index.?;
    }

    const col: i16 = @intCast(coords[0]);
    const row: i16 = @intCast(coords[1]);
    const directions = [4][2]i16{ [2]i16{ col - 1, row }, [2]i16{ col + 1, row }, [2]i16{ col, row - 1 }, [2]i16{ col, row + 1 } };
    const current: u8 = matrix[coords[1]][coords[0]];

    dirloop: for (directions) |dir| {
        if ((dir[0] < 0) or (dir[0] >= cols) or (dir[1] < 0) or (dir[1] >= rows)) continue;

        // Skip coordinate if was already explored
        const new_x: u8 = std.math.cast(u8, dir[0]).?;
        const new_y: u8 = std.math.cast(u8, dir[1]).?;
        const next_coord = [2]u8{ new_x, new_y };
        for (array.items) |plot| {
            for (plot.items) |*seen| {
                if (std.mem.eql(u8, seen, &next_coord)) continue :dirloop;
            }
        }
        // print("Current: {c}, Key {d}, col {d}, row {d}, DIR: {any}\n", .{ current, key, col, row, dir });

        // print("PREV: {d},{d}\n", .{ new_x, new_y });
        if (matrix[new_y][new_x] == current) {
            // print("RECURSION: new {any}, curr {any}\n", .{ matrix[new_y][new_x], current });
            try array.*.items[key].append(allocator, next_coord);
            // print("REC: {any}\n", .{array.*.items[key].items});

            try explorePlot(allocator, array, rows, cols, matrix, next_coord, key);
        }
    }
}

pub fn countPerimeter(array: std.ArrayListUnmanaged([2]u8), width: u32, height: u32) !u32 {
    var count: u32 = 0;
    for (array.items) |coords| {
        const col: i16 = @intCast(coords[0]);
        const row: i16 = @intCast(coords[1]);
        const directions = [4][2]i16{ [2]i16{ col - 1, row }, [2]i16{ col + 1, row }, [2]i16{ col, row - 1 }, [2]i16{ col, row + 1 } };

        dirloop: for (directions) |dir| {
            if ((dir[0] < 0) or (dir[0] >= width) or (dir[1] < 0) or (dir[1] >= height)) {
                count += 1;
                continue;
            }
            const new_x: u8 = std.math.cast(u8, dir[0]).?;
            const new_y: u8 = std.math.cast(u8, dir[1]).?;
            const next_coord = [2]u8{ new_x, new_y };

            for (array.items) |*seen| {
                if (std.mem.eql(u8, seen, &next_coord)) continue :dirloop;
            } else {
                count += 1;
            }
        }
    }
    return count;
}

pub fn countSides(allocator: std.mem.Allocator, array: std.ArrayListUnmanaged([2]u8), width: u32, height: u32) !u32 {
    // Step 1: find all individual walls
    var all_walls: std.ArrayListUnmanaged([4]i16) = .empty;
    defer all_walls.deinit(allocator);

    for (array.items) |coords| {
        const col: i16 = @intCast(coords[0]);
        const row: i16 = @intCast(coords[1]);
        // Wall positions: 0 = right, 1 = bot, 2 = left, 3 = top
        const directions = [4][3]i16{ .{ col - 1, row, 0 }, .{ col + 1, row, 2 }, .{ col, row - 1, 3 }, .{ col, row + 1, 1 } };

        for (directions) |dir| {
            // Vertical wall = 1, horizontal = 0
            const acols: i16 = if (dir[0] == col) 0 else 1;
            const position: i16 = if (dir[0] == col) dir[1] else dir[0];
            const value: i16 = if (dir[0] == col) col else row;
            const next_wall = [4]i16{ acols, position, value, dir[2] };
            // print("NEXT: {any}, DIR: {any}\n", .{ next_wall, dir });

            var is_valid_wall: bool = false;

            // Check if we reach end of matrix
            if ((dir[0] < 0) or (dir[0] >= width) or (dir[1] < 0) or (dir[1] >= height)) {
                is_valid_wall = true;
            } else {
                // Check if we find a different plant
                const new_x: u8 = std.math.cast(u8, dir[0]).?;
                const new_y: u8 = std.math.cast(u8, dir[1]).?;
                const next_coord = [2]u8{ new_x, new_y };
                is_valid_wall = for (array.items) |*item| {
                    if (std.mem.eql(u8, item, &next_coord)) break false;
                } else true;
            }
            // Store wall
            if (is_valid_wall) {
                try all_walls.append(allocator, next_wall);
            }
        }
    }

    // Get unique walls
    var checked_walls: std.ArrayListUnmanaged([4]i16) = .empty;
    defer checked_walls.deinit(allocator);
    var valid_walls: std.ArrayListUnmanaged([4]i16) = .empty;
    defer valid_walls.deinit(allocator);
    // print("ALL: {any}\n", .{all_walls.items});

    main_loop: while (all_walls.items.len > 0) {
        const wall = all_walls.pop().?;
        try checked_walls.append(allocator, wall);
        try valid_walls.append(allocator, wall);
        // print("VALID: {any}\n", .{valid_walls.items});

        pop_loop: while (true) {
            // print("Start PopLoop\n", .{});
            for (all_walls.items, 0..) |item, i| {
                for (checked_walls.items) |check| {
                    const same_acols: bool = item[0] == check[0];
                    const same_pos: bool = item[1] == check[1];
                    const same_side: bool = item[3] == check[3];
                    const value_dif: i16 = @intCast(@abs(item[2] - check[2]));
                    if (same_acols and same_pos and same_side and (value_dif == 1)) {
                        // print("REMOVING: item: {any} check: {any}\n", .{ item, check });

                        _ = all_walls.swapRemove(i);
                        try checked_walls.append(allocator, item);
                        continue :pop_loop;
                    }
                }
            }
            continue :main_loop;
        }
    }

    const count: u32 = @intCast(valid_walls.items.len);
    return count;
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const rows = 140;
    const cols = 140;

    var matrix: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, raw, &matrix);

    var plots: std.ArrayListUnmanaged(std.ArrayListUnmanaged([2]u8)) = .empty;

    for (0..cols) |xcord| {
        yloop: for (0..rows) |ycord| {
            // print("ITERATION: {d},{d}\n", .{ xcord, ycord });
            const x: u8 = @intCast(xcord);
            const y: u8 = @intCast(ycord);
            const next_coord = [2]u8{ x, y };
            for (plots.items) |plot| {
                for (plot.items) |*seen| {
                    if (std.mem.eql(u8, seen, &next_coord)) continue :yloop;
                }
            }
            try explorePlot(allocator, &plots, rows, cols, &matrix, [2]u8{ x, y }, null);
        }
    }

    var res: u32 = 0;
    for (plots.items) |plot| {
        const perim: u32 = try countPerimeter(plot, rows, cols);
        const len: u32 = @intCast(plot.items.len);
        // print("PLOT {d}: LEN: {d}, PERIM: {d}\n", .{ i, len, perim });
        res += len * perim;
    }
    print("Part 1: {d}\n", .{res});

    var res2: u32 = 0;
    for (plots.items) |plot| {
        const sides: u32 = try countSides(allocator, plot, rows, cols);
        const len: u32 = @intCast(plot.items.len);
        res2 += len * sides;
    }
    print("Part 2: {d}\n", .{res2});
}

test "sample" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const rows = 10;
    const cols = 10;

    const sample =
        \\RRRRIICCFF
        \\RRRRIICCCF
        \\VVRRRCCFFF
        \\VVRCCCJFFF
        \\VVVVCJJCFE
        \\VVIVCCJJEE
        \\VVIIICJJEE
        \\MIIIIIJJEE
        \\MIIISIJEEE
        \\MMMISSJEEE
    ;

    var matrix: [rows][cols]u8 = undefined;
    readIntoMatrix(rows, cols, sample, &matrix);

    var plots: std.ArrayListUnmanaged(std.ArrayListUnmanaged([2]u8)) = .empty;

    for (0..cols) |xcord| {
        yloop: for (0..rows) |ycord| {
            const x: u8 = @intCast(xcord);
            const y: u8 = @intCast(ycord);
            const next_coord = [2]u8{ x, y };
            for (plots.items) |plot| {
                for (plot.items) |*seen| {
                    if (std.mem.eql(u8, seen, &next_coord)) continue :yloop;
                }
            }
            try explorePlot(allocator, &plots, rows, cols, &matrix, [2]u8{ x, y }, null);
        }
    }

    var res: u32 = 0;
    for (plots.items, 0..) |plot, i| {
        const perim: u32 = try countPerimeter(plot, rows, cols);
        const len: u32 = @intCast(plot.items.len);
        print("PLOT {d}: LEN: {d}, PERIM: {d}\n\n", .{ i, len, perim });
        res += len * perim;
    }

    var res2: u32 = 0;
    for (plots.items, 0..) |plot, i| {
        const sides: u32 = try countSides(allocator, plot, rows, cols);
        const len: u32 = @intCast(plot.items.len);
        print("PLOT {d}: LEN: {d}, SIDES: {d}\n\n", .{ i, len, sides });
        res2 += len * sides;
    }

    try testing.expect(res == 1930);
    try testing.expect(res2 == 1206);
}
