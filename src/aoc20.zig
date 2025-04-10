const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input20.txt");

pub fn main() !void {
    var debug_allcoator: std.heap.DebugAllocator(.{}) = .init;
    const allocator = debug_allcoator.allocator();

    const rows = 141;
    const cols = 141;

    const matrix: CharMatrix(u8, rows, cols) = .init(raw);

    var map: std.AutoArrayHashMapUnmanaged([2]usize, u16) = .empty;
    defer map.deinit(allocator);
    const start_cell = try mapCellScoresReturnStart(allocator, &map, rows, cols, matrix);

    var cheat_list = try checkCheats(allocator, map, rows, cols, matrix, start_cell);
    defer cheat_list.deinit(allocator);

    var res: usize = 0;
    for (cheat_list.items) |item| {
        if (item.saved >= 100) res += 1;
    }
    print("Result: {d}\n", .{res});

    var res2: usize = 0;
    var cheat_list_2 = try checkCheatsPartTwo(allocator, map, rows, cols, matrix, start_cell);
    defer cheat_list_2.deinit(allocator);
    var iterator = cheat_list_2.iterator();
    while (iterator.next()) |entry| {
        if (entry.value_ptr.* >= 100) res2 += 1;
    }

    print("Result 2: {d}\n", .{res2});
}

pub fn CharMatrix(comptime T: type, comptime rows: u16, comptime cols: u16) type {
    return struct {
        const Self = @This();
        data: [rows * cols]T,
        rows: u16,
        cols: u16,

        pub fn init(data: []const u8) Self {
            var temp: [rows * cols]T = @splat(0);
            var iterator = std.mem.splitScalar(u8, data, '\n');
            var n: usize = 0;
            while (iterator.next()) |row| : (n += 1) {
                if (row.len == 0) break;
                @memcpy(temp[n * cols .. (n + 1) * cols], row);
            }
            return .{ .data = temp, .rows = rows, .cols = cols };
        }

        pub fn get(self: Self, x: usize, y: usize) T {
            std.debug.assert(x < self.cols and y < self.rows);
            return self.data[y * self.cols + x];
        }

        pub fn ptr(self: *Self, x: usize, y: usize) *T {
            std.debug.assert(x < self.cols and y < self.rows);
            return &self.data[y * self.cols + x];
        }

        pub fn printMatrix(self: Self) void {
            for (0..self.rows) |y| {
                const row = self.data[y * self.cols .. (y + 1) * self.cols];
                print("{s}\n", .{row});
            }
        }
    };
}

pub fn mapCellScoresReturnStart(allocator: std.mem.Allocator, map: *std.AutoArrayHashMapUnmanaged([2]usize, u16), comptime rows: u16, comptime cols: u16, matrix: CharMatrix(u8, rows, cols)) ![2]usize {
    var path_len: u16 = 1;
    for (matrix.data) |cell| {
        if (cell == '.') path_len += 1;
    }

    const start_index = std.mem.indexOf(u8, &matrix.data, "S").?;
    const start_cell = [2]usize{ start_index % matrix.cols, start_index / matrix.cols };

    var cell: [2]usize = start_cell;
    var prev_cell: [2]usize = start_cell;
    var distance: u16 = path_len;
    while (true) : (distance -= 1) {
        try map.put(allocator, cell, distance);
        if (matrix.get(cell[0], cell[1]) == 'E') break;
        const x = cell[0];
        const y = cell[1];
        const next_cells = [4][2]usize{ [2]usize{ x - 1, y }, [2]usize{ x + 1, y }, [2]usize{ x, y - 1 }, [2]usize{ x, y + 1 } };
        for (next_cells) |next| {
            if (std.mem.eql(usize, &next, &prev_cell)) continue;
            if (matrix.get(next[0], next[1]) == '#') continue;
            prev_cell = cell;
            cell = next;
            break;
        }
    }
    return start_cell;
}

const Cheat = struct { start: [2]usize, end: [2]usize, distance: u16, saved: i32 };

pub fn checkCheats(allocator: std.mem.Allocator, map: std.AutoArrayHashMapUnmanaged([2]usize, u16), comptime rows: u16, comptime cols: u16, matrix: CharMatrix(u8, rows, cols), start: [2]usize) !std.ArrayListUnmanaged(Cheat) {
    var list: std.ArrayListUnmanaged(Cheat) = .empty;

    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        const cell = entry.key_ptr.*;
        //print("\n Cell is: {any}", .{cell});
        const xi: i16 = @intCast(cell[0]);
        const yi: i16 = @intCast(cell[1]);
        //const movements = [4][2]i16{ [2]i16{ -1, 0 }, [2]i16{ 1, 0 }, [2]i16{ 0, -1 }, [2]i16{ 0, 1 } };
        const movements: [4][2]i16 = .{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } };
        for (movements) |mov| {
            const next_xi = xi + mov[0];
            const next_yi = yi + mov[1];
            const next2_xi = xi + mov[0] * 2;
            const next2_yi = yi + mov[1] * 2;

            const next_x: usize = @intCast(next_xi);
            const next_y: usize = @intCast(next_yi);
            if (matrix.get(next_x, next_y) != '#') continue;

            if ((next2_yi < 0) or (next2_yi >= rows) or (next2_xi < 0) or (next2_xi >= cols)) continue;
            const next2_x: usize = @intCast(next2_xi);
            const next2_y: usize = @intCast(next2_yi);
            if (matrix.get(next2_x, next2_y) == '#') continue;

            const next_cell: [2]usize = .{ next_x, next_y };
            const next2_cell: [2]usize = .{ next2_x, next2_y };
            const new_distance = map.get(start).? - map.get(cell).? + map.get(next2_cell).? + 2;
            if (new_distance >= map.get(start).?) continue;

            const saved: i32 = map.get(start).? - new_distance;
            const new_cheat = Cheat{ .start = next_cell, .end = next2_cell, .distance = new_distance, .saved = saved };
            try list.append(allocator, new_cheat);
        }
    }

    return list;
}

pub fn checkCheatsPartTwo(allocator: std.mem.Allocator, map: std.AutoArrayHashMapUnmanaged([2]usize, u16), comptime rows: u16, comptime cols: u16, matrix: CharMatrix(u8, rows, cols), start: [2]usize) !std.AutoArrayHashMapUnmanaged([4]usize, i32) {
    //    var list: std.ArrayListUnmanaged(Cheat) = .empty;
    var cheatmap: std.AutoArrayHashMapUnmanaged([4]usize, i32) = .empty;
    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        const cell = entry.key_ptr.*;
        //print("\n Cell is: {any}", .{cell});
        const xi: i16 = @intCast(cell[0]);
        const yi: i16 = @intCast(cell[1]);

        for (0..41) |xm| {
            for (0..41) |ym| {
                const xmi: i32 = std.math.cast(i32, xm).? - 20;
                const ymi: i32 = std.math.cast(i32, ym).? - 20;

                if ((@abs(xmi) + @abs(ymi)) > 20) continue;
                const next_xi = xi + xmi;
                const next_yi = yi + ymi;

                if ((next_yi < 0) or (next_yi >= rows) or (next_xi < 0) or (next_xi >= cols)) continue;
                const next_x: usize = @intCast(next_xi);
                const next_y: usize = @intCast(next_yi);
                if (matrix.get(next_x, next_y) == '#') continue;

                const next_cell: [2]usize = .{ next_x, next_y };
                const new_distance: u16 = @intCast(map.get(start).? - map.get(cell).? + map.get(next_cell).? + @abs(xmi) + @abs(ymi));
                if (new_distance >= map.get(start).?) continue;

                const saved: i32 = map.get(start).? - new_distance;

                //const new_cheat = Cheat{ .start = cell, .end = next_cell, .distance = new_distance, .saved = saved };
                const new_cheat = [4]usize{ cell[0], cell[1], next_cell[0], next_cell[1] };
                if (cheatmap.contains(new_cheat)) continue;
                try cheatmap.put(allocator, new_cheat, saved);
            }
        }
    }

    return cheatmap;
}
test "sample" {
    const sample =
        \\###############
        \\#...#...#.....#
        \\#.#.#.#.#.###.#
        \\#S#...#.#.#...#
        \\#######.#.#.###
        \\#######.#.#...#
        \\#######.#.###.#
        \\###..E#...#...#
        \\###.#######.###
        \\#...###...#...#
        \\#.#####.#.###.#
        \\#.#...#.#.#...#
        \\#.#.#.#.#.#.###
        \\#...#...#...###
        \\###############
    ;

    const allocator = testing.allocator;

    const rows = 15;
    const cols = 15;

    var matrix: CharMatrix(u8, rows, cols) = .init(sample);

    matrix.printMatrix();

    var map: std.AutoArrayHashMapUnmanaged([2]usize, u16) = .empty;
    defer map.deinit(allocator);
    const start_cell = try mapCellScoresReturnStart(allocator, &map, rows, cols, matrix);

    print("Paths: {d}\n", .{map.count()});

    var cheat_list = try checkCheats(allocator, map, rows, cols, matrix, start_cell);
    defer cheat_list.deinit(allocator);

    //for (cheat_list.items) |item| {
    //    print("Cheat path: {any}\n", .{item});
    //}
    //print("Cheats: {d}\n", .{cheat_list.items.len});
    try testing.expect(cheat_list.items.len == 44);

    var cheat_list_2 = try checkCheatsPartTwo(allocator, map, rows, cols, matrix, start_cell);
    defer cheat_list_2.deinit(allocator);

    //for (cheat_list_2.items) |item| {
    //    print("Cheat 2 path: {any}\n", .{item});
    //}
    var iterator = cheat_list_2.iterator();
    var s76: u16 = 0;
    var s74: u16 = 0;
    var s72: u16 = 0;
    var s62: u16 = 0;
    var s50: u16 = 0;
    while (iterator.next()) |entry| {
        //print("Cheat 2 path: {any} - Saved {d}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        if (entry.value_ptr.* == 76) s76 += 1;
        if (entry.value_ptr.* == 74) {
            s74 += 1;
            //print("Cheat {d}: {any}\n", .{ entry.value_ptr.*, entry.key_ptr.* });
        }
        if (entry.value_ptr.* == 72) s72 += 1;
        if (entry.value_ptr.* == 62) s62 += 1;
        if (entry.value_ptr.* == 50) s50 += 1;
    }
    print("Saved 76: {d}, 74: {d}, 72: {d}, 62: {d}, 50: {d}\n", .{ s76, s74, s72, s62, s50 });
    //print("Cheats 2: {d}\n", .{cheat_list_2.items.len});
}
