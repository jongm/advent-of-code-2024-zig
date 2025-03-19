const std = @import("std");
const testing = std.testing;

const raw = @embedFile("inputs/input15.txt");

pub fn main() void {
    const rows = 50;
    const cols = 50;

    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();
    var queue: std.ArrayListUnmanaged(?[5]usize) = .empty;
    defer queue.deinit(allocator);

    var matrix: [rows][cols]u8 = undefined;

    var iterator = std.mem.splitSequence(u8, raw, "\n\n");
    parseMap(iterator.next().?, rows, cols, &matrix);
    printMap(matrix);

    const robot_index = std.mem.indexOf(u8, raw, "@").?;
    const init_row: usize = robot_index / (cols + 1);
    const init_col: usize = robot_index % (cols + 1);

    var position = [2]usize{ init_row, init_col };
    // std.debug.print("Index {d} Char at {d},{d} is {c}\n", .{ robot_index, init_row, init_col, matrix[init_row][init_col] });

    for (iterator.next().?) |inst| {
        if (inst == '\n') continue;
        queue.clearAndFree(allocator);
        const new_position = try findNextPosition(allocator, queue, rows, cols, &matrix, position, inst, 1);
        if (new_position != null) {
            moveObject(rows, cols, &matrix, queue);
            position = new_position.?;
            // std.debug.print("Char at {d},{d} is {c}\n", .{ new_position.?[0], new_position.?[1], matrix_wide[new_position.?[0]][new_position.?[1]] });
        }
        // printMap(matrix);
    }
    printMap(matrix);

    const res = countBoxes(&matrix);
    std.debug.print("RESULT: {d}\n", .{res});

    // SECOND PART
    std.debug.print("SECOND PART \n\n\n", .{});

    iterator.reset();

    parseMap(iterator.next().?, rows, cols, &matrix);
    printMap(matrix);

    var matrix_wide: [rows][cols * 2]u8 = undefined;
    doubleWideMap(rows, cols, &matrix, &matrix_wide);
    printMap(matrix_wide);

    const init_row2: usize = robot_index / (cols + 1);
    const init_col2: usize = (robot_index % (cols + 1)) * 2;

    position = [2]usize{ init_row2, init_col2 };

    for (iterator.next().?) |inst| {
        if (inst == '\n') continue;
        queue.clearAndFree(allocator);
        // std.debug.print("\x1B[2J\x1B[H\n", .{});
        const new_position = try findNextPosition(allocator, queue, rows, cols * 2, &matrix_wide, inst, 1);
        if (new_position != null) {
            moveObject(rows, cols * 2, &matrix_wide, queue);
            position = new_position.?;
            // std.debug.print("Char at {d},{d} is {c}\n", .{ new_position.?[0], new_position.?[1], matrix_wide[new_position.?[0]][new_position.?[1]] });
        }
        // printMap(matrix_wide);
        // std.time.sleep(1000 * 1000 * 500);
    }
    printMap(matrix_wide);

    const res2 = countBoxes(&matrix_wide);
    std.debug.print("RESULT 2: {d}\n", .{res2});
}

pub fn parseMap(string: []const u8, comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8) void {
    var iterator = std.mem.splitScalar(u8, string, '\n');
    var row: u8 = 0;
    while (iterator.next()) |values| : (row += 1) {
        if (values.len == 0) break;
        matrix.*[row] = values[0..cols].*;
    }
}

pub fn findNextPosition(allocator: std.mem.Allocator, queue: *std.ArrayListUnmanaged(?[5]usize), comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8, start_position: [2]usize, instruction: u8, depth: usize) !?[2]usize {
    const row_int: i16 = @intCast(start_position[0]);
    const col_int: i16 = @intCast(start_position[1]);

    var new_row_int: i16 = undefined;
    var new_col_int: i16 = undefined;

    switch (instruction) {
        '<', 'a' => {
            new_row_int = row_int;
            new_col_int = col_int - 1;
        },
        '^', 'w' => {
            new_row_int = row_int - 1;
            new_col_int = col_int;
        },
        '>', 'd' => {
            new_row_int = row_int;
            new_col_int = col_int + 1;
        },
        'v', 's' => {
            new_row_int = row_int + 1;
            new_col_int = col_int;
        },
        else => unreachable,
    }

    const new_row: usize = @intCast(new_row_int);
    const new_col: usize = @intCast(new_col_int);

    const next_cell: u8 = matrix[new_row][new_col];
    const next_position = [2]usize{ new_row, new_col };

    const new_position = switch (next_cell) {
        '#' => null,
        'O' => blk: {
            const new_box_pos = try findNextPosition(allocator, queue, rows, cols, matrix, next_position, instruction, depth + 1);
            if (new_box_pos == null) {
                break :blk null;
            } else {
                break :blk next_position;
            }
        },
        '.' => next_position,
        '[', ']' => blk: {
            if ((instruction == '<') or (instruction == '>') or (instruction == 'a') or (instruction == 'd')) {
                const new_box_pos = try findNextPosition(allocator, queue, rows, cols, matrix, next_position, instruction, depth + 1);
                if (new_box_pos == null) {
                    break :blk null;
                } else {
                    break :blk next_position;
                }
            } else {
                switch (next_cell) {
                    '[' => {
                        const next_position_right = [2]usize{ next_position[0], next_position[1] + 1 };
                        const new_box_pos_left = try findNextPosition(allocator, queue, rows, cols, matrix, next_position, instruction, depth + 1);
                        const new_box_pos_right = try findNextPosition(allocator, queue, rows, cols, matrix, next_position_right, instruction, depth + 1);
                        if ((new_box_pos_left == null) or (new_box_pos_right == null)) {
                            break :blk null;
                        } else {
                            // try queue.append(allocator, [4]usize{ start_position[0], start_position[1], next_position_right[0], next_position_right[1] });
                            break :blk next_position;
                        }
                    },
                    ']' => {
                        const next_position_left = [2]usize{ next_position[0], next_position[1] - 1 };
                        const new_box_pos_left = try findNextPosition(allocator, queue, rows, cols, matrix, next_position_left, instruction, depth + 1);
                        const new_box_pos_right = try findNextPosition(allocator, queue, rows, cols, matrix, next_position, instruction, depth + 1);
                        if ((new_box_pos_left == null) or (new_box_pos_right == null)) {
                            break :blk null;
                        } else {
                            // try queue.append(allocator, [4]usize{ start_position[0], start_position[1], next_position_left[0], next_position_left[1] });
                            break :blk next_position;
                        }
                    },
                    else => unreachable,
                }
            }
        },
        else => unreachable,
    };

    if (new_position != null) {
        try queue.append(allocator, [5]usize{ start_position[0], start_position[1], new_position.?[0], new_position.?[1], depth });
    } else {
        try queue.append(allocator, null);
    }
    return new_position;
}

pub fn moveObject(comptime rows: u8, comptime cols: u8, matrix: *[rows][cols]u8, queue: std.ArrayListUnmanaged(?[5]usize)) void {
    var max_depth: usize = 1;
    var do_move: bool = true;
    const unmovable = "#.";

    for (queue.items) |move| {
        if (move == null) {
            do_move = false;
        } else {
            max_depth = @max(max_depth, move.?[4] + 1);
        }
    }

    if (do_move) {
        while (max_depth > 0) : (max_depth -= 1) {
            moveloop: for (queue.items) |move| {
                if (move.?[4] != max_depth) continue;
                const current_cell: u8 = matrix[move.?[0]][move.?[1]];
                for (unmovable) |unm| {
                    if (current_cell == unm) continue :moveloop;
                }
                matrix.*[move.?[0]][move.?[1]] = '.';
                matrix.*[move.?[2]][move.?[3]] = current_cell;
                // std.debug.print("\n Move ({c}) from ({d},{d}) to ({d},{d}) with depth {d}\n", .{ current_cell, move.?[0], move.?[1], move.?[2], move.?[3], max_depth });
            }
        }
    }
}

pub fn printMap(matrix: anytype) void {
    for (matrix) |row| {
        for (row) |cell| {
            std.debug.print("{c}", .{cell});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

pub fn countBoxes(matrix: anytype) usize {
    var res: usize = 0;
    for (matrix, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            if ((cell == 'O') or (cell == '[')) {
                res += i * 100 + j;
            }
        }
    }
    return res;
}

pub fn doubleWideMap(comptime rows: u8, comptime cols: u8, original: *[rows][cols]u8, target: *[rows][cols * 2]u8) void {
    for (original, 0..) |row, r| {
        for (row, 0..) |cell, c| {
            const wide_cells: [2]u8 = switch (cell) {
                '#' => [2]u8{ '#', '#' },
                'O' => [2]u8{ '[', ']' },
                '.' => [2]u8{ '.', '.' },
                '@' => [2]u8{ '@', '.' },
                else => unreachable,
            };
            target[r][c * 2] = wide_cells[0];
            target[r][c * 2 + 1] = wide_cells[1];
        }
    }
}

test "sample" {
    const sample =
        \\##########
        \\#..O..O.O#
        \\#......O.#
        \\#.OO..O.O#
        \\#..O@..O.#
        \\#O#..O...#
        \\#O..O..O.#
        \\#.OO.O.OO#
        \\#....O...#
        \\##########
    ;
    // const moves =
    //     \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
    //     \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
    //     \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
    //     \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
    //     \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
    //     \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
    //     \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
    //     \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
    //     \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
    //     \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
    // ;
    // _ = moves;
    const allocator = testing.allocator;
    var queue: std.ArrayListUnmanaged(?[5]usize) = .empty;
    defer queue.deinit(allocator);
    const rows = 10;
    const cols = 10;

    var matrix: [rows][cols]u8 = undefined;

    parseMap(sample, rows, cols, &matrix);
    printMap(matrix);

    const robot_index = std.mem.indexOf(u8, sample, "@").?;
    const init_row: usize = robot_index / (cols + 1);
    const init_col: usize = robot_index % (cols + 1);

    var position = [2]usize{ init_row, init_col };
    // std.debug.print("Index {d} Char at {d},{d} is {c}\n", .{ robot_index, init_row, init_col, matrix[init_row][init_col] });
    // const stdin = std.io.getStdIn();

    // for (moves) |inst| {
    // if (inst == '\n') continue;
    const stdin = std.io.getStdIn();
    var buffer = [_]u8{ 0, 0 };
    while (true) {
        queue.clearAndFree(allocator);
        _ = try stdin.reader().readUntilDelimiter(&buffer, '\n');
        std.debug.print("\x1B[2J\x1B[H\n", .{});
        // std.debug.print("\n Buffer: {any}\n", .{buffer});
        const inst = buffer[0];

        const new_position = try findNextPosition(allocator, &queue, rows, cols, &matrix, position, inst, 1);
        if (new_position != null) {
            moveObject(rows, cols, &matrix, queue);
            position = new_position.?;
            // std.debug.print("Char at {d},{d} is {c}\n", .{ new_position.?[0], new_position.?[1], matrix_wide[new_position.?[0]][new_position.?[1]] });
        }
        printMap(matrix);
    }
    // std.debug.print("\x1B[2J\x1B[H", .{});
    printMap(matrix);
    // var buffer = [_]u8{ 0, 0 };
    // _ = try stdin.reader().readUntilDelimiter(&buffer, '\n');

    const res = countBoxes(&matrix);
    std.debug.print("\n SAMPLE: {d}\n", .{res});

    try testing.expect(res == 10092);
}

test "wide" {
    const sample =
        \\##########
        \\#..O..O.O#
        \\#......O.#
        \\#.OO..O.O#
        \\#..O@..O.#
        \\#O#..O...#
        \\#O..O..O.#
        \\#.OO.O.OO#
        \\#....O...#
        \\##########
    ;
    const rows = 10;
    const cols = 10;
    const moves =
        \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
        \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
        \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
        \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
        \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
        \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
        \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
        \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
        \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
        \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
    ;

    const allocator = testing.allocator;
    var queue: std.ArrayListUnmanaged(?[5]usize) = .empty;
    defer queue.deinit(allocator);

    var matrix: [rows][cols]u8 = undefined;
    parseMap(sample, rows, cols, &matrix);

    printMap(matrix);

    var matrix_wide: [rows][cols * 2]u8 = undefined;
    doubleWideMap(rows, cols, &matrix, &matrix_wide);
    printMap(matrix_wide);

    const robot_index = std.mem.indexOf(u8, sample, "@").?;
    const init_row: usize = robot_index / (cols + 1);
    const init_col: usize = (robot_index % (cols + 1)) * 2;

    var position = [2]usize{ init_row, init_col };

    for (moves) |inst| {
        if (inst == '\n') continue;
        // const stdin = std.io.getStdIn();
        // var buffer = [_]u8{ 0, 0 };
        // while (true) {
        // _ = try stdin.reader().readUntilDelimiter(&buffer, '\n');
        // std.debug.print("\x1B[2J\x1B[H\n", .{});

        // const inst = buffer[0];
        queue.clearAndFree(allocator);
        const new_position = try findNextPosition(allocator, &queue, rows, cols * 2, &matrix_wide, position, inst, 1);
        if (new_position != null) {
            moveObject(rows, cols * 2, &matrix_wide, queue);
            position = new_position.?;
        }
        // printMap(matrix_wide);
    }
    printMap(matrix_wide);

    const res = countBoxes(&matrix_wide);
    std.debug.print("\n SAMPLE WIDE: {d}\n", .{res});
    try testing.expect(res == 9021);
}

test "wide2" {
    const sample =
        \\#######
        \\#...#.#
        \\#.....#
        \\#.....#
        \\#.....#
        \\#.....#
        \\#.OOO@#
        \\#.OOO.#
        \\#..O..#
        \\#.....#
        \\#.....#
        \\#######
    ;
    const moves = "v<vv<<^^^^^";

    const allocator = testing.allocator;
    var queue: std.ArrayListUnmanaged(?[5]usize) = .empty;
    defer queue.deinit(allocator);

    const rows = 12;
    const cols = 7;

    var matrix: [rows][cols]u8 = undefined;
    parseMap(sample, rows, cols, &matrix);

    printMap(matrix);

    var matrix_wide: [rows][cols * 2]u8 = undefined;
    doubleWideMap(rows, cols, &matrix, &matrix_wide);
    printMap(matrix_wide);

    const robot_index = std.mem.indexOf(u8, sample, "@").?;
    const init_row: usize = robot_index / (cols + 1);
    const init_col: usize = (robot_index % (cols + 1)) * 2;
    // std.debug.print("START {d} - {d},{d} is {c}\n", .{ robot_index, init_row, init_col, matrix_wide[init_row][init_col] });

    var position = [2]usize{ init_row, init_col };
    for (moves) |inst| {
        if (inst == '\n') continue;
        // std.debug.print("\x1B[2J\x1B[H\n", .{});
        const new_position = findNextPosition(rows, cols * 2, &matrix_wide, position[0], position[1], inst);
        if (new_position != null) {
            moveObject(rows, cols * 2, &matrix_wide, position[0], position[1], new_position.?);
            position = new_position.?;
        }
    }
    printMap(matrix_wide);

    const res = countBoxes(&matrix_wide);
    std.debug.print("\n SAMPLE WIDE: {d}\n", .{res});
    try testing.expect(res == 2339);

    // // INTERACTIVE TEST
    // const stdin = std.io.getStdIn();
    // var buffer = [_]u8{ 0, 0 };
    // var i: u8 = 0;
    // while (true) : (i += 1) {
    //     _ = try stdin.reader().readUntilDelimiter(&buffer, '\n');
    //     std.debug.print("\x1B[2J\x1B[H\n", .{});
    //     std.debug.print("\n Buffer: {any}\n", .{buffer});

    //     const inst = buffer[0];
    //     queue.clearAndFree(allocator);

    //     const new_position = try findNextPosition(allocator, &queue, rows, cols * 2, &matrix_wide, position, inst, 1);
    //     if (new_position != null) {
    //         moveObject(rows, cols * 2, &matrix_wide, queue);
    //         position = new_position.?;
    //         // std.debug.print("Char at {d},{d} is {c}\n", .{ new_position.?[0], new_position.?[1], matrix_wide[new_position.?[0]][new_position.?[1]] });
    //     }

    //     printMap(matrix_wide);
    //     std.debug.print("\n Instruction: {c}\n", .{inst});
    // }
}
