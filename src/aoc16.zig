const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input16.txt");

const Node = struct {
    f: usize,
    g: usize,
    h: usize,
    pos: [2]usize,
    previous: [2]usize,
    facing: [2]i16,
};

pub fn parseMap(string: []const u8, comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8) void {
    var iterator = std.mem.splitScalar(u8, string, '\n');
    var row: u8 = 0;
    while (iterator.next()) |values| : (row += 1) {
        if (values.len == 0) break;
        matrix.*[row] = values[0..cols].*;
    }
}

pub fn printMap(matrix: anytype) void {
    for (matrix) |row| {
        for (row) |cell| {
            print("{c}", .{cell});
        }
        print("\n", .{});
    }
    print("\n", .{});
}

const WrongPositionsError = error{MoreThanOneNodeApartError};

pub fn calcDistance(start: [2]usize, end: [2]usize, facing: ?[2]i16) !usize {

    // Facings: East (0,1) - South (1, 0) - West (0, -1) - North (-1, 0)
    const dist_x = @max(start[0], end[0]) - @min(start[0], end[0]);
    const dist_y = @max(start[1], end[1]) - @min(start[1], end[1]);
    const move_distance: usize = dist_x + dist_y;
    if (facing == null) {
        return move_distance;
    } else {
        const end_row_int: i16 = @intCast(end[0]);
        const end_col_int: i16 = @intCast(end[1]);
        const start_row_int: i16 = @intCast(start[0]);
        const start_col_int: i16 = @intCast(start[1]);

        const dif_row: i16 = end_row_int - start_row_int;
        const dif_col: i16 = end_col_int - start_col_int;
        if ((@abs(dif_row) > 1) or (@abs(dif_col) > 1)) return WrongPositionsError.MoreThanOneNodeApartError;
        const turn_distance: usize = @max(@abs(dif_row - facing.?[0]), @abs(dif_col - facing.?[1]));
        const total_distance: usize = move_distance + (turn_distance * 1000);
        // print("DIST from {any} to {any}: Difs[{d},{d}], total: {d}\n", .{ start, end, dif_row, dif_col, total_distance });

        return total_distance;
    }
}

pub fn main() !void {
    const rows = 141;
    const cols = 141;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();

    var matrix: [rows][cols]u8 = undefined;
    parseMap(raw, rows, cols, &matrix);

    const start_index = std.mem.indexOf(u8, raw, "S").?;
    const start_pos = [2]usize{ start_index / (cols + 1), start_index % (cols + 1) };

    const end_index = std.mem.indexOf(u8, raw, "E").?;
    const end_pos = [2]usize{ end_index / (cols + 1), end_index % (cols + 1) };

    const start_facing = [2]i16{ 0, 1 };

    var result_path = (try aStarAlgo(allocator, rows, cols, &matrix, start_pos, end_pos, start_facing)).?;
    defer result_path.deinit(allocator);

    const cost = result_path.items[0].f;

    // // printMap(matrix);
    // print("\n\n\n", .{});
    // for (result_path.items) |node| {
    //     matrix[node.pos[0]][node.pos[1]] = 'O';
    // }
    // // printMap(matrix);
    print("Result: {d}\n", .{cost});

    // PART 2

    const best_nodes = try getAllBestNodes(allocator, rows, cols, &matrix, end_pos, cost, result_path);

    // print("Crossing {any}", .{node});
    for (best_nodes.items) |best| {
        matrix[best[0]][best[1]] = 'O';
    }

    var res2: usize = 0;
    for (matrix) |row| {
        for (row) |cell| {
            if ((cell == 'O') or (cell == 'E') or (cell == 'S')) res2 += 1;
        }
    }
    // printMap(matrix);

    print("Result 2 {d}\n", .{res2});
}

test "calc_distance" {
    const dist1 = try calcDistance([2]usize{ 3, 3 }, [2]usize{ 3, 4 }, [2]i16{ 0, -1 });
    const dist2 = try calcDistance([2]usize{ 3, 3 }, [2]usize{ 3, 2 }, [2]i16{ 0, -1 });
    const dist3 = try calcDistance([2]usize{ 3, 3 }, [2]usize{ 4, 3 }, [2]i16{ 1, 0 });
    const dist4 = try calcDistance([2]usize{ 3, 3 }, [2]usize{ 4, 3 }, [2]i16{ 0, 1 });
    const dist5 = try calcDistance([2]usize{ 3, 3 }, [2]usize{ 3, 4 }, [2]i16{ 0, -1 });
    const dist6 = try calcDistance([2]usize{ 3, 3 }, [2]usize{ 2, 3 }, [2]i16{ 1, 0 });
    const dist7 = try calcDistance([2]usize{ 3, 3 }, [2]usize{ 8, 5 }, null);
    const dist8 = try calcDistance([2]usize{ 5, 7 }, [2]usize{ 2, 1 }, null);
    print("Distances: 1: {d}, 2: {d}, 3: {d}, 4: {d}, 5: {d}, 6: {d}, 7: {d}, 8: {d} \n", .{ dist1, dist2, dist3, dist4, dist5, dist6, dist7, dist8 });

    try testing.expect(dist1 == 2001);
    try testing.expect(dist2 == 1);
    try testing.expect(dist3 == 1);
    try testing.expect(dist4 == 1001);
    try testing.expect(dist5 == 2001);
    try testing.expect(dist6 == 2001);
    try testing.expect(dist7 == 7);
    try testing.expect(dist8 == 9);
}

pub fn aStarAlgo(allocator: std.mem.Allocator, comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8, start: [2]usize, end: [2]usize, start_facing: [2]i16) !?std.ArrayListUnmanaged(Node) {
    var unexplored_nodes: std.AutoHashMapUnmanaged([2]usize, Node) = .empty;
    defer unexplored_nodes.deinit(allocator);
    var explored_nodes: std.AutoHashMapUnmanaged([2]usize, Node) = .empty;
    defer explored_nodes.deinit(allocator);

    // Row, Col, F
    var path: std.ArrayListUnmanaged(Node) = .empty;

    var current_node = Node{ .f = 0, .g = 0, .h = 0, .pos = start, .previous = [2]usize{ 0, 0 }, .facing = start_facing };
    try unexplored_nodes.put(allocator, start, current_node);

    while (unexplored_nodes.count() > 0) {

        // Find next best node
        var iterator = unexplored_nodes.iterator();
        var min_f: usize = 999999;
        var min_key: [2]usize = undefined;
        while (iterator.next()) |node| {
            if (node.value_ptr.f < min_f) {
                min_f = node.value_ptr.f;
                min_key = node.key_ptr.*;
            }
        }
        current_node = unexplored_nodes.get(min_key).?;
        // print("CURRENT NODE: {any}, {any}\n", .{ min_key, current_node });

        _ = unexplored_nodes.remove(min_key);
        try explored_nodes.put(allocator, min_key, current_node);

        // Return path
        if (std.mem.eql(usize, &min_key, &end)) {
            while (current_node.f > 0) {
                try path.append(allocator, current_node);
                current_node = explored_nodes.get(current_node.previous).?;
            }
            return path;
        }

        // Work on the node
        const row_int: i16 = @intCast(min_key[0]);
        const col_int: i16 = @intCast(min_key[1]);
        const directions = [4][2]i16{ [_]i16{ row_int - 1, col_int }, [_]i16{ row_int + 1, col_int }, [_]i16{ row_int, col_int - 1 }, [_]i16{ row_int, col_int + 1 } };

        for (directions) |dir| {
            if ((dir[0] < 0) or (dir[1] < 0) or (dir[0] >= rows) or (dir[1] >= cols)) continue;

            const new_row: usize = @intCast(dir[0]);
            const new_col: usize = @intCast(dir[1]);
            const new_pos = [2]usize{ new_row, new_col };

            if (explored_nodes.contains(new_pos) or (matrix[new_row][new_col] == '#')) continue;

            // print("TRYING CAST {d} - {d}\n", .{ new_pos[0], min_key[0] });
            const dif_row: i16 = @intCast(dir[0] - row_int);
            // print("TRYING CAST {d} - {d}\n", .{ new_pos[1], min_key[1] });
            const dif_col: i16 = @intCast(dir[1] - col_int);
            const new_facing = [2]i16{ dif_row, dif_col };

            const g: usize = current_node.g + try calcDistance(min_key, new_pos, current_node.facing);
            const h: usize = try calcDistance(new_pos, end, null);
            const f: usize = g + h;
            // print("DIST G from {any} to {any} + {d}, total: {d}\n", .{ min_key, new_pos, current_node.g, g });
            // print("DIST H from {any} to {any}, total: {d}\n", .{ new_pos, end, h });

            if (unexplored_nodes.contains(new_pos)) {
                if (g >= unexplored_nodes.get(new_pos).?.g) continue;
            }

            const new_node = Node{ .f = f, .g = g, .h = h, .pos = new_pos, .previous = [2]usize{ min_key[0], min_key[1] }, .facing = new_facing };
            try unexplored_nodes.put(allocator, new_pos, new_node);
        }
    }

    return null;
}

pub fn getAllBestNodes(allocator: std.mem.Allocator, comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8, end_position: [2]usize, best_cost: usize, result_path: std.ArrayListUnmanaged(Node)) !std.ArrayListUnmanaged([2]usize) {
    var best_nodes: std.ArrayListUnmanaged([2]usize) = .empty;
    for (result_path.items) |node| {
        try best_nodes.append(allocator, node.pos);
    }

    for (result_path.items) |node| {
        const row_int: i16 = @intCast(node.pos[0]);
        const col_int: i16 = @intCast(node.pos[1]);
        const directions = [4][2]i16{ [_]i16{ row_int - 1, col_int }, [_]i16{ row_int + 1, col_int }, [_]i16{ row_int, col_int - 1 }, [_]i16{ row_int, col_int + 1 } };

        for (directions) |dir| {
            if ((dir[0] < 0) or (dir[1] < 0) or (dir[0] >= rows) or (dir[1] >= cols)) continue;

            const new_row: usize = @intCast(dir[0]);
            const new_col: usize = @intCast(dir[1]);
            const new_pos = [2]usize{ new_row, new_col };
            const dif_row: i16 = @intCast(dir[0] - row_int);
            const dif_col: i16 = @intCast(dir[1] - col_int);
            const new_facing = [2]i16{ dif_row, dif_col };

            const new_g: usize = node.g + try calcDistance(node.pos, new_pos, node.facing);

            if (matrix[new_row][new_col] == '#') continue;

            const other_path = try aStarAlgo(allocator, rows, cols, matrix, new_pos, end_position, new_facing);

            if (other_path) |other| {
                if (other.items.len == 0) continue;
                const other_cost = other.items[0].f + new_g;
                if (other_cost == best_cost) {
                    itemloop: for (other.items) |item| {
                        const best_node = [2]usize{ item.pos[0], item.pos[1] };
                        for (best_nodes.items) |best| {
                            if (std.mem.eql(usize, &best, &best_node)) continue :itemloop;
                        }
                        try best_nodes.append(allocator, best_node);
                    }
                    for (best_nodes.items) |best| {
                        if (std.mem.eql(usize, &best, &new_pos)) continue;
                    }
                    try best_nodes.append(allocator, new_pos);
                }
            }
        }
    }

    return best_nodes;
}

test "sample" {
    const sample =
        \\###############
        \\#.......#....E#
        \\#.#.###.#.###.#
        \\#.....#.#...#.#
        \\#.###.#####.#.#
        \\#.#.#.......#.#
        \\#.#.#####.###.#
        \\#...........#.#
        \\###.#.#####.#.#
        \\#...#.....#.#.#
        \\#.#.#.###.#.#.#
        \\#.....#...#.#.#
        \\#.###.#.#.#.#.#
        \\#S..#.....#...#
        \\###############
    ;

    const rows = 15;
    const cols = 15;

    const allocator = testing.allocator;

    var matrix: [rows][cols]u8 = undefined;
    parseMap(sample, rows, cols, &matrix);

    const start_index = std.mem.indexOf(u8, sample, "S").?;
    const start_pos = [2]usize{ start_index / (cols + 1), start_index % (cols + 1) };

    const end_index = std.mem.indexOf(u8, sample, "E").?;
    const end_pos = [2]usize{ end_index / (cols + 1), end_index % (cols + 1) };

    const start_facing = [2]i16{ 0, 1 };

    var result_path = (try aStarAlgo(allocator, rows, cols, &matrix, start_pos, end_pos, start_facing)).?;

    printMap(matrix);
    print("\n\n\n", .{});
    for (result_path.items) |node| {
        // print("Crossing {any}", .{node});
        matrix[node.pos[0]][node.pos[1]] = 'O';
        // print(" - Done!\n", .{});
    }
    printMap(matrix);
    const cost = result_path.items[0].f;
    print("Total Cost is {d}\n", .{cost});
    try testing.expect(cost == 7036);
    result_path.deinit(allocator);
}

test "sample2" {
    const sample =
        \\###############
        \\#.......#....E#
        \\#.#.###.#.###.#
        \\#.....#.#...#.#
        \\#.###.#####.#.#
        \\#.#.#.......#.#
        \\#.#.#####.###.#
        \\#...........#.#
        \\###.#.#####.#.#
        \\#...#.....#.#.#
        \\#.#.#.###.#.#.#
        \\#.....#...#.#.#
        \\#.###.#.#.#.#.#
        \\#S..#.....#...#
        \\###############
    ;

    const rows = 15;
    const cols = 15;

    const debug_allocator = testing.allocator;
    var arena = std.heap.ArenaAllocator.init(debug_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var matrix: [rows][cols]u8 = undefined;
    parseMap(sample, rows, cols, &matrix);

    const start_index = std.mem.indexOf(u8, sample, "S").?;
    const start_pos = [2]usize{ start_index / (cols + 1), start_index % (cols + 1) };

    const end_index = std.mem.indexOf(u8, sample, "E").?;
    const end_pos = [2]usize{ end_index / (cols + 1), end_index % (cols + 1) };

    const start_facing = [2]i16{ 0, 1 };

    const result_path = (try aStarAlgo(allocator, rows, cols, &matrix, start_pos, end_pos, start_facing)).?;
    const cost = result_path.items[0].f;

    const best_nodes = try getAllBestNodes(allocator, rows, cols, &matrix, end_pos, cost, result_path);

    // print("Crossing {any}", .{node});
    for (best_nodes.items) |best| {
        matrix[best[0]][best[1]] = 'O';
    }
    print("\n\n\n", .{});

    var res2: usize = 0;
    for (matrix) |row| {
        for (row) |cell| {
            if ((cell == 'O') or (cell == 'E') or (cell == 'S')) res2 += 1;
        }
    }
    printMap(matrix);

    print("Result2 {d}\n", .{res2});
    try testing.expect(res2 == 45);
}

test "sample2_2" {
    const sample =
        \\#################
        \\#...#...#...#..E#
        \\#.#.#.#.#.#.#.#.#
        \\#.#.#.#...#...#.#
        \\#.#.#.#.###.#.#.#
        \\#...#.#.#.....#.#
        \\#.#.#.#.#.#####.#
        \\#.#...#.#.#.....#
        \\#.#.#####.#.###.#
        \\#.#.#.......#...#
        \\#.#.###.#####.###
        \\#.#.#...#.....#.#
        \\#.#.#.#####.###.#
        \\#.#.#.........#.#
        \\#.#.#.#########.#
        \\#S#.............#
        \\#################
    ;

    const rows = 17;
    const cols = 17;

    const debug_allocator = testing.allocator;
    var arena = std.heap.ArenaAllocator.init(debug_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var matrix: [rows][cols]u8 = undefined;
    parseMap(sample, rows, cols, &matrix);

    const start_index = std.mem.indexOf(u8, sample, "S").?;
    const start_pos = [2]usize{ start_index / (cols + 1), start_index % (cols + 1) };

    const end_index = std.mem.indexOf(u8, sample, "E").?;
    const end_pos = [2]usize{ end_index / (cols + 1), end_index % (cols + 1) };

    const start_facing = [2]i16{ 0, 1 };

    const result_path = (try aStarAlgo(allocator, rows, cols, &matrix, start_pos, end_pos, start_facing)).?;
    const cost = result_path.items[0].f;

    const best_nodes = try getAllBestNodes(allocator, rows, cols, &matrix, end_pos, cost, result_path);

    // print("Crossing {any}", .{node});
    for (best_nodes.items) |best| {
        matrix[best[0]][best[1]] = 'O';
    }
    print("\n\n\n", .{});

    var res2: usize = 0;
    for (matrix) |row| {
        for (row) |cell| {
            if ((cell == 'O') or (cell == 'E') or (cell == 'S')) res2 += 1;
        }
    }
    printMap(matrix);

    print("Result2 {d}\n", .{res2});
    try testing.expect(res2 == 64);
}
