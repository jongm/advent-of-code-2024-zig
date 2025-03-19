const std = @import("std");
const testing = std.testing;

const raw = @embedFile("inputs/input12.txt");

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

pub fn explore_plot(allocator: std.mem.Allocator, array: *std.ArrayListUnmanaged(std.ArrayListUnmanaged([2]u8)), matrix: anytype, coords: [2]u8, index: ?u16) !void {

    // Add to list if its the same letter
    var key: u16 = undefined;
    if (index == null) {
        key = @intCast(array.items.len);
        try array.*.append(allocator, std.ArrayListUnmanaged([2]u8).empty);
        try array.*.items[key].append(allocator, coords);
    } else {
        key = index.?;
    }

    const xi: i16 = @intCast(coords[0]);
    const yi: i16 = @intCast(coords[1]);
    const directions = [4][2]i16{ [2]i16{ xi - 1, yi }, [2]i16{ xi + 1, yi }, [2]i16{ xi, yi - 1 }, [2]i16{ xi, yi + 1 } };
    const current: u8 = matrix.data[coords[1]][coords[0]];

    dirloop: for (directions) |dir| {
        if ((dir[0] < 0) or (dir[0] >= matrix.width) or (dir[1] < 0) or (dir[1] >= matrix.height)) continue;

        // Skip coordinate if was already explored
        const new_x: u8 = std.math.cast(u8, dir[0]).?;
        const new_y: u8 = std.math.cast(u8, dir[1]).?;
        const next_coord = [2]u8{ new_x, new_y };
        for (array.items) |plot| {
            for (plot.items) |*seen| {
                if (std.mem.eql(u8, seen, &next_coord)) continue :dirloop;
            }
        }
        // std.debug.print("Current: {c}, Key {d}, XI {d}, YI {d}, DIR: {any}\n", .{ current, key, xi, yi, dir });

        // std.debug.print("PREV: {d},{d}\n", .{ new_x, new_y });
        if (matrix.data[new_y][new_x] == current) {
            // std.debug.print("RECURSION: new {any}, curr {any}\n", .{ matrix.data[new_y][new_x], current });
            try array.*.items[key].append(allocator, next_coord);
            // std.debug.print("REC: {any}\n", .{array.*.items[key].items});

            try explore_plot(allocator, array, matrix, next_coord, key);
        }
    }
}

pub fn count_perimeter(array: std.ArrayListUnmanaged([2]u8), width: u32, height: u32) !u32 {
    var count: u32 = 0;
    for (array.items) |coords| {
        const xi: i16 = @intCast(coords[0]);
        const yi: i16 = @intCast(coords[1]);
        const directions = [4][2]i16{ [2]i16{ xi - 1, yi }, [2]i16{ xi + 1, yi }, [2]i16{ xi, yi - 1 }, [2]i16{ xi, yi + 1 } };

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

pub fn count_sides(allocator: std.mem.Allocator, array: std.ArrayListUnmanaged([2]u8), width: u32, height: u32) !u32 {
    // Step 1: find all individual walls
    var all_walls: std.ArrayListUnmanaged([4]i16) = .empty;
    defer all_walls.deinit(allocator);

    for (array.items) |coords| {
        const xi: i16 = @intCast(coords[0]);
        const yi: i16 = @intCast(coords[1]);
        // Wall positions: 0 = right, 1 = bot, 2 = left, 3 = top
        const directions = [4][3]i16{ [_]i16{ xi - 1, yi, 0 }, [_]i16{ xi + 1, yi, 2 }, [_]i16{ xi, yi - 1, 3 }, [_]i16{ xi, yi + 1, 1 } };

        for (directions) |dir| {
            // Vertical wall = 1, horizontal = 0
            const axis: i16 = if (dir[0] == xi) 0 else 1;
            const position: i16 = if (dir[0] == xi) dir[1] else dir[0];
            const value: i16 = if (dir[0] == xi) xi else yi;
            const next_wall = [4]i16{ axis, position, value, dir[2] };
            // std.debug.print("NEXT: {any}, DIR: {any}\n", .{ next_wall, dir });

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
    // std.debug.print("ALL: {any}\n", .{all_walls.items});

    main_loop: while (all_walls.items.len > 0) {
        const wall = all_walls.pop().?;
        try checked_walls.append(allocator, wall);
        try valid_walls.append(allocator, wall);
        // std.debug.print("VALID: {any}\n", .{valid_walls.items});

        pop_loop: while (true) {
            // std.debug.print("Start PopLoop\n", .{});
            for (all_walls.items, 0..) |item, i| {
                for (checked_walls.items) |check| {
                    const same_axis: bool = item[0] == check[0];
                    const same_pos: bool = item[1] == check[1];
                    const same_side: bool = item[3] == check[3];
                    const value_dif: i16 = @intCast(@abs(item[2] - check[2]));
                    if (same_axis and same_pos and same_side and (value_dif == 1)) {
                        // std.debug.print("REMOVING: item: {any} check: {any}\n", .{ item, check });

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

    const dimX = 140;
    const dimY = 140;

    var matrix = create_matrix_struct(u8, dimX, dimY){};
    read_into_matrix(dimX, dimY, raw, &matrix.data);

    var plots: std.ArrayListUnmanaged(std.ArrayListUnmanaged([2]u8)) = .empty;

    for (0..matrix.width) |xcord| {
        yloop: for (0..matrix.height) |ycord| {
            // std.debug.print("ITERATION: {d},{d}\n", .{ xcord, ycord });
            const x: u8 = @intCast(xcord);
            const y: u8 = @intCast(ycord);
            const next_coord = [2]u8{ x, y };
            for (plots.items) |plot| {
                for (plot.items) |*seen| {
                    if (std.mem.eql(u8, seen, &next_coord)) continue :yloop;
                }
            }
            try explore_plot(allocator, &plots, &matrix, [2]u8{ x, y }, null);
        }
    }

    var res: u32 = 0;
    for (plots.items) |plot| {
        const perim: u32 = try count_perimeter(plot, dimX, dimY);
        const len: u32 = @intCast(plot.items.len);
        // std.debug.print("PLOT {d}: LEN: {d}, PERIM: {d}\n", .{ i, len, perim });
        res += len * perim;
    }
    std.debug.print("RESULT: {d}\n", .{res});

    var res2: u32 = 0;
    for (plots.items) |plot| {
        const sides: u32 = try count_sides(allocator, plot, dimX, dimY);
        const len: u32 = @intCast(plot.items.len);
        res2 += len * sides;
    }
    std.debug.print("RESULT 2: {d}\n", .{res2});
}

test "sample" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const testX = 10;
    const testY = 10;

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

    var matrix = create_matrix_struct(u8, testX, testY){};
    read_into_matrix(testX, testY, sample, &matrix.data);

    var plots: std.ArrayListUnmanaged(std.ArrayListUnmanaged([2]u8)) = .empty;

    for (0..matrix.width) |xcord| {
        yloop: for (0..matrix.height) |ycord| {
            const x: u8 = @intCast(xcord);
            const y: u8 = @intCast(ycord);
            const next_coord = [2]u8{ x, y };
            for (plots.items) |plot| {
                for (plot.items) |*seen| {
                    if (std.mem.eql(u8, seen, &next_coord)) continue :yloop;
                }
            }
            try explore_plot(allocator, &plots, &matrix, [2]u8{ x, y }, null);
        }
    }

    var res: u32 = 0;
    for (plots.items, 0..) |plot, i| {
        const perim: u32 = try count_perimeter(plot, testX, testY);
        const len: u32 = @intCast(plot.items.len);
        std.debug.print("PLOT {d}: LEN: {d}, PERIM: {d}\n\n", .{ i, len, perim });
        res += len * perim;
    }

    var res2: u32 = 0;
    for (plots.items, 0..) |plot, i| {
        const sides: u32 = try count_sides(allocator, plot, testX, testY);
        const len: u32 = @intCast(plot.items.len);
        std.debug.print("PLOT {d}: LEN: {d}, SIDES: {d}\n\n", .{ i, len, sides });
        res2 += len * sides;
    }

    try testing.expect(res == 1930);
    try testing.expect(res2 == 1206);
}
