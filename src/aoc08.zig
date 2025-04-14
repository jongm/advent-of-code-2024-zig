const std = @import("std");
const testing = std.testing;

const raw = @embedFile("inputs/input8.txt");

// var gpa = std.heap.GeneralPurposeAllocator(.{}){};
// const gpa_allocator = gpa.allocator();

var gpa = std.heap.DebugAllocator(.{}){};
const gpa_allocator = gpa.allocator();

const MAX_CHARS = 8;
const DIMX = 50;
const DIMY = 50;

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

pub fn calculate_nodes(matrix: anytype, node1: [2]usize, node2: [2]usize, dimx: i16, dimy: i16) void {
    const x1: i16 = @intCast(node1[0]);
    const y1: i16 = @intCast(node1[1]);
    const x2: i16 = @intCast(node2[0]);
    const y2: i16 = @intCast(node2[1]);

    const anti1_x: i16 = x1 - x2 + x1;
    const anti1_y: i16 = y1 - y2 + y1;
    const anti2_x: i16 = x2 - x1 + x2;
    const anti2_y: i16 = y2 - y1 + y2;

    if ((anti1_x >= 0) and (anti1_y >= 0) and (anti1_x < dimx) and (anti1_y < dimy)) {
        matrix.data[std.math.cast(usize, anti1_y).?][std.math.cast(usize, anti1_x).?] = '*';
    }
    if ((anti2_x >= 0) and (anti2_y >= 0) and (anti2_x < dimx) and (anti2_y < dimy)) {
        matrix.data[std.math.cast(usize, anti2_y).?][std.math.cast(usize, anti2_x).?] = '*';
    }
}

pub fn calculate_nodes_harmonic(matrix: anytype, node1: [2]usize, node2: [2]usize, dimx: i16, dimy: i16) void {
    const x1: i16 = @intCast(node1[0]);
    const y1: i16 = @intCast(node1[1]);
    const x2: i16 = @intCast(node2[0]);
    const y2: i16 = @intCast(node2[1]);

    // This only works because the nodes coordinates are always from smaller to bigger
    const shift_x: i16 = x2 - x1;
    const shift_y: i16 = y2 - y1;
    // std.debug.print("SHIFTS: {d}, {d}\n", .{ shift_x, shift_y });

    var jumps: u8 = 0;
    var new_x: i16 = x1 - shift_x;
    var new_y: i16 = y1 - shift_y;
    while ((new_x >= 0) and (new_y >= 0) and (new_x < dimx) and (new_y < dimy)) {
        jumps += 1;
        new_x -= shift_x;
        new_y -= shift_y;
    }

    var start_x: i16 = x1 - (shift_x * jumps);
    var start_y: i16 = y1 - (shift_y * jumps);

    // std.debug.print("JUMPS: {d}, {d}, from {d}, {d}, to {d}, {d}\n", .{ jumps_x, jumps_y, x1, y1, start_x, start_y });

    while ((start_x >= 0) and (start_y >= 0) and (start_x < dimx) and (start_y < dimy)) {
        matrix.data[std.math.cast(usize, start_y).?][std.math.cast(usize, start_x).?] = '*';
        start_x += shift_x;
        start_y += shift_y;
    }
}

pub fn nodes_to_map(data: []const u8, map: *std.AutoHashMapUnmanaged(u8, std.ArrayListUnmanaged([2]usize)), allocator: std.mem.Allocator, dimx: u8, dimy: u8) !void {
    for (data, 0..) |char, pos| {
        if ((char == '.') or (char == '\n')) continue;
        if (!map.contains(char)) {
            try map.put(allocator, char, std.ArrayListUnmanaged([2]usize).empty);
        }
        // try map.put(char, map.get(char).? + 1);
        var list = map.getPtr(char).?;
        const x: usize = std.math.cast(usize, pos).? % @as(usize, dimx + 1);
        const y: usize = std.math.cast(usize, pos).? / @as(usize, dimy + 1);
        try list.append(allocator, [2]usize{ x, y });
        // std.debug.print("TEMP: {any} - {any}\n", .{ char, list.items });
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var map: std.AutoHashMapUnmanaged(u8, std.ArrayListUnmanaged([2]usize)) = .empty;

    try nodes_to_map(raw, &map, allocator, DIMX, DIMY);

    var matrix = create_matrix_struct(u8, DIMX, DIMY){};
    read_into_matrix(DIMX, DIMY, raw, &matrix.data);

    var matrix2 = create_matrix_struct(u8, DIMX, DIMY){};
    read_into_matrix(DIMX, DIMY, raw, &matrix2.data);

    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        for (0..entry.value_ptr.items.len) |i| {
            for (0..entry.value_ptr.items.len) |j| {
                if (i < j) {
                    _ = calculate_nodes(&matrix, entry.value_ptr.items[i], entry.value_ptr.items[j], DIMX, DIMY);
                    _ = calculate_nodes_harmonic(&matrix2, entry.value_ptr.items[i], entry.value_ptr.items[j], DIMX, DIMY);
                }
            }
        }
    }

    var res: u16 = 0;
    for (matrix.data) |row| {
        for (row) |cell| {
            if (cell == '*') {
                res += 1;
            }
        }
    }
    std.debug.print("RESULT: {d}\n", .{res});

    var res2: u16 = 0;
    for (matrix2.data) |row| {
        for (row) |cell| {
            if (cell == '*') {
                res2 += 1;
            }
        }
    }
    std.debug.print("RESULT 2: {d}\n", .{res2});
}

test "example" {
    const sample =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;

    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var map: std.AutoHashMapUnmanaged(u8, std.ArrayListUnmanaged([2]usize)) = .empty;

    try nodes_to_map(sample, &map, allocator, 12, 12);

    var matrix = create_matrix_struct(u8, 12, 12){};
    read_into_matrix(12, 12, sample, &matrix.data);

    var matrix2 = create_matrix_struct(u8, 12, 12){};
    read_into_matrix(12, 12, sample, &matrix2.data);

    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        for (0..entry.value_ptr.items.len) |i| {
            for (0..entry.value_ptr.items.len) |j| {
                if (i < j) {
                    _ = calculate_nodes(&matrix, entry.value_ptr.items[i], entry.value_ptr.items[j], 12, 12);
                    _ = calculate_nodes_harmonic(&matrix2, entry.value_ptr.items[i], entry.value_ptr.items[j], 12, 12);
                }
            }
        }
    }

    var res: u16 = 0;
    for (matrix.data) |row| {
        for (row) |cell| {
            if (cell == '*') {
                res += 1;
            }
        }
    }
    std.debug.print("RESULT: {d}\n", .{res});

    var res2: u16 = 0;
    for (matrix2.data) |row| {
        for (row) |cell| {
            if (cell == '*') {
                res2 += 1;
            }
        }
    }
    std.debug.print("RESULT 2: {d}\n", .{res2});

    try testing.expect(res == 14);
    try testing.expect(res2 == 34);
}
