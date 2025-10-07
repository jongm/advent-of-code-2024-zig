const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input06.txt");

const Path = struct { positions: std.AutoHashMapUnmanaged([3]usize, void), is_loop: bool };

pub fn readIntoMatrix(comptime rows: u8, comptime cols: u8, string: []const u8, target: *[rows][cols]u8) void {
    var lines = std.mem.splitScalar(u8, string, '\n');
    var row: u8 = 0;
    while (lines.next()) |line| : (row += 1) {
        if (line.len == 0) break;
        target[row] = line[0..cols].*;
    }
}

const directions = [_][2]i16{ [2]i16{ 0, -1 }, [2]i16{ 1, 0 }, [2]i16{ 0, 1 }, [2]i16{ -1, 0 } };

pub fn walkMatrix(comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8, start: [2]usize, allocator: std.mem.Allocator) !Path {
    var row = start[0];
    var col = start[1];
    var dir: usize = 0;
    std.debug.assert(matrix[row][col] == '^');

    var seen: std.AutoHashMapUnmanaged([3]usize, void) = .empty;

    while (true) {
        try seen.put(allocator, [3]usize{ row, col, dir }, {});

        const newcol: i16 = std.math.cast(i16, col).? + directions[dir][0];
        const newrow: i16 = std.math.cast(i16, row).? + directions[dir][1];
        const in_map: bool = ((newcol >= 0) and (newcol <= cols - 1) and (newrow <= rows - 1) and (newrow >= 0));
        if (!in_map) {
            return .{ .positions = seen, .is_loop = false };
        }

        const newcol_u = std.math.cast(usize, newcol).?;
        const newrow_u = std.math.cast(usize, newrow).?;

        if (matrix[newrow_u][newcol_u] == '#') {
            if (dir == 3) {
                dir = 0;
            } else {
                dir += 1;
            }
            continue;
        }

        if (seen.contains([3]usize{ newrow_u, newcol_u, dir })) {
            return .{ .positions = seen, .is_loop = true };
        }
        col = newcol_u;
        row = newrow_u;
    }
}

pub fn findUniquePositions(positions: std.AutoHashMapUnmanaged([3]usize, void), allocator: std.mem.Allocator) !std.AutoHashMapUnmanaged([2]usize, void) {
    var unique: std.AutoHashMapUnmanaged([2]usize, void) = .empty;

    var pos_iterator = positions.keyIterator();
    while (pos_iterator.next()) |key_ptr| {
        try unique.put(allocator, [2]usize{ key_ptr.*[0], key_ptr.*[1] }, {});
    }
    return unique;
}

pub fn main() !void {
    const rows = 130;
    const cols = 130;

    var matrix: [rows][cols]u8 = undefined;

    const pos = std.mem.indexOfScalar(u8, raw, '^').?;
    const start_col: usize = std.math.cast(usize, pos % @as(usize, cols + 1)).?;
    const start_row: usize = std.math.cast(usize, pos / @as(usize, rows + 1)).?;
    const start_pos = [2]usize{ start_row, start_col };

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();

    readIntoMatrix(rows, cols, raw, &matrix);
    var original_path = try walkMatrix(rows, cols, &matrix, start_pos, allocator);
    defer original_path.positions.deinit(allocator);

    var unique_path = try findUniquePositions(original_path.positions, allocator);
    defer unique_path.deinit(allocator);

    print("Result 1: {d}\n", .{unique_path.count()});

    var res2: usize = 0;
    var path_iterator = unique_path.keyIterator();
    while (path_iterator.next()) |key_ptr| {
        const position = [2]usize{ key_ptr.*[0], key_ptr.*[1] };
        if (std.mem.eql(usize, &position, &start_pos)) {
            continue;
        }
        matrix[position[0]][position[1]] = '#';
        var new_path = try walkMatrix(rows, cols, &matrix, [2]usize{ start_row, start_col }, allocator);
        if (new_path.is_loop) {
            res2 += 1;
        }
        matrix[position[0]][position[1]] = '.';
        new_path.positions.deinit(allocator);
    }
    print("Result 2: {d}\n", .{res2});
}
