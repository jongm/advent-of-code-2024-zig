const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input18.txt");

const Node = struct {
    f: usize,
    g: usize,
    h: usize,
    pos: [2]usize,
    previous: [2]usize,
};

pub fn calcDistance(start: [2]usize, end: [2]usize) !usize {
    const dist_x = @max(start[0], end[0]) - @min(start[0], end[0]);
    const dist_y = @max(start[1], end[1]) - @min(start[1], end[1]);
    const move_distance: usize = dist_x + dist_y;
    return move_distance;
}

pub fn aStarAlgo(allocator: std.mem.Allocator, comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8, start: [2]usize, end: [2]usize) !?std.ArrayListUnmanaged(Node) {
    var unexplored_nodes: std.AutoHashMapUnmanaged([2]usize, Node) = .empty;
    defer unexplored_nodes.deinit(allocator);
    var explored_nodes: std.AutoHashMapUnmanaged([2]usize, Node) = .empty;
    defer explored_nodes.deinit(allocator);

    var path: std.ArrayListUnmanaged(Node) = .empty;

    var current_node = Node{ .f = 0, .g = 0, .h = 0, .pos = start, .previous = [2]usize{ 0, 0 } };
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

            const g: usize = current_node.g + try calcDistance(min_key, new_pos);
            const h: usize = try calcDistance(new_pos, end);
            const f: usize = g + h;

            if (unexplored_nodes.contains(new_pos)) {
                if (g >= unexplored_nodes.get(new_pos).?.g) continue;
            }

            const new_node = Node{ .f = f, .g = g, .h = h, .pos = new_pos, .previous = [2]usize{ min_key[0], min_key[1] } };
            try unexplored_nodes.put(allocator, new_pos, new_node);
        }
    }

    return null;
}

pub fn parseBytes(allocator: std.mem.Allocator, string: []const u8, list: *std.ArrayListUnmanaged([2]usize)) !void {
    var iterator = std.mem.splitScalar(u8, string, '\n');
    while (iterator.next()) |row| {
        if (row.len == 0) break;
        var nums_iter = std.mem.splitScalar(u8, row, ',');
        const num1 = try std.fmt.parseInt(usize, nums_iter.next().?, 10);
        const num2 = try std.fmt.parseInt(usize, nums_iter.next().?, 10);
        const byte = [2]usize{ num2, num1 };
        try list.append(allocator, byte);
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

pub fn main() !void {
    const rows = 71;
    const cols = 71;

    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    const allocator = debug_allocator.allocator();

    var matrix: [rows][cols]u8 = undefined;
    for (0..rows) |row| {
        for (0..cols) |col| {
            matrix[row][col] = '.';
        }
    }
    var bytes: std.ArrayListUnmanaged([2]usize) = .empty;
    defer bytes.deinit(allocator);
    try parseBytes(allocator, raw, &bytes);

    const n: usize = 1024;

    for (0..n) |i| {
        const byte = bytes.items[i];
        matrix[byte[0]][byte[1]] = '#';
    }
    // printMap(matrix);

    var path = (try aStarAlgo(allocator, rows, cols, &matrix, [2]usize{ 0, 0 }, [2]usize{ rows - 1, cols - 1 })).?;
    defer path.deinit(allocator);

    for (path.items) |node| {
        matrix[node.pos[0]][node.pos[1]] = 'O';
    }
    // printMap(matrix);

    var res: usize = 0;

    for (matrix) |row| {
        for (row) |cell| {
            if (cell == 'O') res += 1;
        }
    }

    print("Result: {d}\n", .{res});

    for (n..bytes.items.len) |i| {
        const byte = bytes.items[i];
        matrix[byte[0]][byte[1]] = '#';
        var path2 = try aStarAlgo(allocator, rows, cols, &matrix, [2]usize{ 0, 0 }, [2]usize{ rows - 1, cols - 1 });
        if (path2 == null) {
            print("Result 2: {d},{d} at {d}", .{ byte[1], byte[0], i });
            break;
        } else {
            path2.?.deinit(allocator);
        }
    }
}

test "sample" {
    const sample =
        \\5,4
        \\4,2
        \\4,5
        \\3,0
        \\2,1
        \\6,3
        \\2,4
        \\1,5
        \\0,6
        \\3,3
        \\2,6
        \\5,1
        \\1,2
        \\5,5
        \\2,5
        \\6,5
        \\1,4
        \\0,4
        \\6,4
        \\1,1
        \\6,1
        \\1,0
        \\0,5
        \\1,6
        \\2,0
    ;

    const rows = 7;
    const cols = 7;

    const allocator = testing.allocator;

    var matrix: [rows][cols]u8 = undefined;
    for (0..rows) |row| {
        for (0..cols) |col| {
            matrix[row][col] = '.';
        }
    }
    var bytes: std.ArrayListUnmanaged([2]usize) = .empty;
    defer bytes.deinit(allocator);
    try parseBytes(allocator, sample, &bytes);

    const n: usize = 12;

    for (0..n) |i| {
        const byte = bytes.items[i];
        matrix[byte[0]][byte[1]] = '#';
    }
    printMap(matrix);

    var path = (try aStarAlgo(allocator, rows, cols, &matrix, [2]usize{ 0, 0 }, [2]usize{ rows - 1, cols - 1 })).?;
    defer path.deinit(allocator);

    for (path.items) |node| {
        matrix[node.pos[0]][node.pos[1]] = 'O';
    }
    printMap(matrix);

    var res: usize = 0;

    for (matrix) |row| {
        for (row) |cell| {
            if (cell == 'O') res += 1;
        }
    }

    try testing.expect(res == 22);
}
