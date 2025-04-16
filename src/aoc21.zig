const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input21.txt");

pub fn findStepsDigits(allocator: std.mem.Allocator, target: u8, k1: *u8) ![]u8 {
    const keypad = "789456123x0A";
    const target_pos = std.mem.indexOfScalar(u8, keypad, target).?;
    const current_pos = std.mem.indexOfScalar(u8, keypad, k1.*).?;

    const row_t: usize = target_pos / 3;
    const col_t: usize = target_pos % 3;
    var row_c: usize = current_pos / 3;
    var col_c: usize = current_pos % 3;
    //print("Target RC({d},{d}) Current RC ({d},{d})\n", .{ row_t, col_t, row_c, col_c });

    var buffer: [10]u8 = @splat(0);
    var len: u8 = 0;

    // Order of operations hardcoded for solution
    if ((row_c == 3) and (col_t == 0)) { // Special case 1
        while (row_t < row_c) : (row_c -= 1) {
            buffer[len] = '^';
            len += 1;
        }
        while (col_t < col_c) : (col_c -= 1) {
            buffer[len] = '<';
            len += 1;
        }
    }
    if ((col_c == 0) and (row_t == 3)) { // Special case 2
        while (col_t > col_c) : (col_c += 1) {
            buffer[len] = '>';
            len += 1;
        }
        while (row_t > row_c) : (row_c += 1) {
            buffer[len] = 'v';
            len += 1;
        }
    }
    // Normal cases
    while (col_t < col_c) : (col_c -= 1) {
        buffer[len] = '<';
        len += 1;
    }
    while (row_t < row_c) : (row_c -= 1) {
        buffer[len] = '^';
        len += 1;
    }
    while (row_t > row_c) : (row_c += 1) {
        buffer[len] = 'v';
        len += 1;
    }
    while (col_t > col_c) : (col_c += 1) {
        buffer[len] = '>';
        len += 1;
    }

    buffer[len] = 'A';
    //print("From {c} to {c}: {s}\n", .{ k1.*, target, buffer[0 .. len + 1] });
    k1.* = target;
    const moves = try allocator.dupe(u8, buffer[0 .. len + 1]);
    return moves;
}

test "find steps digits" {
    const allocator = testing.allocator;
    var k1: u8 = '8';
    const moves = try findStepsDigits(allocator, 'A', &k1);
    defer allocator.free(moves);
    print("8 to A: {s} {c}\n", .{ moves, k1 });
    try testing.expect(k1 == 'A');
    try testing.expectEqualSlices(u8, "vvv>A", moves);
    const moves2 = try findStepsDigits(allocator, '4', &k1);
    defer allocator.free(moves2);
    print("A to 4: {s} {c}\n", .{ moves2, k1 });
    try testing.expect(k1 == '4');
    try testing.expectEqualSlices(u8, "^^<<A", moves2);
}

pub fn findStepsArrows(allocator: std.mem.Allocator, target: u8, key: *u8) ![]u8 {
    const output: []const u8 = switch (key.*) {
        'v' => switch (target) {
            'v' => "A",
            '>' => ">A",
            '<' => "<A",
            '^' => "^A",
            'A' => "^>A",
            else => unreachable,
        },
        '>' => switch (target) {
            'v' => "<A",
            '>' => "A",
            '<' => "<<A",
            '^' => "<^A",
            'A' => "^A",
            else => unreachable,
        },
        '<' => switch (target) {
            'v' => ">A",
            '>' => ">>A",
            '<' => "A",
            '^' => ">^A",
            'A' => ">>^A",
            else => unreachable,
        },
        '^' => switch (target) {
            'v' => "vA",
            '>' => "v>A",
            '<' => "v<A",
            '^' => "A",
            'A' => ">A",
            else => unreachable,
        },
        'A' => switch (target) {
            'v' => "<vA",
            '>' => "vA",
            '<' => "v<<A",
            '^' => "<A",
            'A' => "A",
            else => unreachable,
        },
        else => unreachable,
    };

    key.* = target;
    const moves = try allocator.dupe(u8, output);
    return moves;
}

test "find steps arrows" {
    const allocator = testing.allocator;
    var key: u8 = '<';
    const moves = try findStepsArrows(allocator, 'A', &key);
    defer allocator.free(moves);
    print("< to A: {s} {c}\n", .{ moves, key });
    try testing.expect(key == 'A');
    try testing.expectEqualSlices(u8, ">>^A", moves);
    const moves2 = try findStepsArrows(allocator, 'v', &key);
    defer allocator.free(moves2);
    print("A to v: {s} {c}\n", .{ moves2, key });
    try testing.expect(key == 'v');
    try testing.expectEqualSlices(u8, "<vA", moves2);
}

pub fn typeCode(allocator: std.mem.Allocator, code: []const u8, k1: *u8, k2: *u8, k3: *u8, list1: *std.ArrayListUnmanaged([]u8), list2: *std.ArrayListUnmanaged([]u8), list3: *std.ArrayListUnmanaged([]u8)) !void {
    for (code) |char| {
        const steps1 = try findStepsDigits(allocator, char, k1);
        try list1.append(allocator, steps1);
        for (steps1) |s1| {
            const steps2 = try findStepsArrows(allocator, s1, k2);
            try list2.append(allocator, steps2);
            for (steps2) |s2| {
                const steps3 = try findStepsArrows(allocator, s2, k3);
                try list3.append(allocator, steps3);
            }
        }
    }
}

pub fn findStepsRecursive(allocator: std.mem.Allocator, char: u8, keymaps: *[]u8, current: u8, max: u8, memo: *std.AutoArrayHashMapUnmanaged([3]u8, u64)) !u64 {
    var temp_var: u64 = 0;
    const next_steps = try findStepsArrows(allocator, char, &keymaps.*[current]);
    if (current == max - 1) return next_steps.len;
    for (next_steps) |next| {
        const step_args: [3]u8 = .{ next, keymaps.*[current + 1], current + 1 };
        var partial: u64 = undefined;
        if (memo.contains(step_args)) {
            partial = memo.get(step_args).?;
            keymaps.*[current + 1] = next; // If we dont recalculate then the pointer gets old
            //print("Found {any} value: {d}]\n", .{ step_args, partial });
        } else {
            partial = try findStepsRecursive(allocator, next, keymaps, current + 1, max, memo);
            try memo.put(allocator, step_args, partial);
            //print("WRITING {any} value: {d}]\n", .{ step_args, partial });
        }
        temp_var += partial;
    }
    return temp_var;
}

pub fn countList(list: std.ArrayListUnmanaged([]u8)) u64 {
    var len: u64 = 0;
    for (list.items) |item| len += item.len;
    return len;
}

pub fn listToString(allocator: std.mem.Allocator, list: *std.ArrayListUnmanaged([]u8)) ![]u8 {
    var buffer_len: usize = 0;
    for (list.items) |item| buffer_len += item.len;
    var buffer = try allocator.alloc(u8, buffer_len);

    var len: usize = 0;
    for (list.items) |item| {
        const new_len = item.len;
        @memcpy(buffer[len .. len + new_len], item[0..new_len]);
        len += new_len;
    }
    return buffer;
}

pub fn main() !void {
    var debug_alloc = std.heap.DebugAllocator(.{}).init;
    var arena = std.heap.ArenaAllocator.init(debug_alloc.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    var keypad1: u8 = 'A';
    var keypad2: u8 = 'A';
    var keypad3: u8 = 'A';

    var list1: std.ArrayListUnmanaged([]u8) = .empty;
    var list2: std.ArrayListUnmanaged([]u8) = .empty;
    var list3: std.ArrayListUnmanaged([]u8) = .empty;

    var res: usize = 0;
    var iterator = std.mem.splitScalar(u8, raw, '\n');
    while (iterator.next()) |code| {
        if (code.len == 0) break;
        keypad1 = 'A';
        keypad2 = 'A';
        keypad3 = 'A';
        list1.clearRetainingCapacity();
        list2.clearRetainingCapacity();
        list3.clearRetainingCapacity();
        try typeCode(allocator, code, &keypad1, &keypad2, &keypad3, &list1, &list2, &list3);
        //const moves1 = try listToString(allocator, &list1);
        //const moves2 = try listToString(allocator, &list2);
        const moves3 = try listToString(allocator, &list3);

        const code_number = try std.fmt.parseInt(usize, code[0..3], 10);
        const complexity = code_number * moves3.len;
        res += complexity;
    }

    print("Result: {d}", .{res});

    var memo: std.AutoArrayHashMapUnmanaged([3]u8, u64) = .empty;
    const max_robots: u8 = 25;

    var res2: usize = 0;
    iterator.reset();
    while (iterator.next()) |code| {
        if (code.len == 0) break;

        memo.clearRetainingCapacity();

        var k1: u8 = 'A';
        var buffer = try allocator.alloc(u8, max_robots);
        for (0..buffer.len) |i| buffer[i] = 'A';
        const current: u8 = 0;

        var code_res: u64 = 0;
        for (code) |char| {
            const steps1 = try findStepsDigits(allocator, char, &k1);
            for (steps1) |step| {
                const partial = try findStepsRecursive(allocator, step, &buffer, current, max_robots, &memo);
                code_res += partial;
            }
        }

        const code_number = try std.fmt.parseInt(u64, code[0..3], 10);
        const complexity = code_number * code_res;
        // print("\n\nPART 2: Code: {s}, Complexity: {d} [{d}, {d}]\n", .{ code, complexity, code_number, code_res });
        res2 += complexity;
    }

    print("\nResult 2: {d}\n", .{res2});
}

test "sample" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sample: [5][]const u8 = .{ "029A", "980A", "179A", "456A", "379A" };

    var keypad1: u8 = 'A';
    var keypad2: u8 = 'A';
    var keypad3: u8 = 'A';

    var list1: std.ArrayListUnmanaged([]u8) = .empty;
    var list2: std.ArrayListUnmanaged([]u8) = .empty;
    var list3: std.ArrayListUnmanaged([]u8) = .empty;

    try typeCode(allocator, sample[0], &keypad1, &keypad2, &keypad3, &list1, &list2, &list3);

    print("\n\nList 1:\n", .{});
    for (list1.items) |item| print("{s}", .{item});
    print("\n\nList 2:\n", .{});
    for (list2.items) |item| print("{s}", .{item});
    print("\n\nList 3:\n", .{});
    for (list3.items) |item| print("{s}", .{item});

    const moves1 = try listToString(allocator, &list1);
    const moves2 = try listToString(allocator, &list2);
    const moves3 = try listToString(allocator, &list3);

    try testing.expect(moves1.len == 12);
    try testing.expect(moves2.len == 28);
    try testing.expect(moves3.len == 68);
}

test "sample full" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sample: [5][]const u8 = .{ "029A", "980A", "179A", "456A", "379A" };

    var keypad1: u8 = 'A';
    var keypad2: u8 = 'A';
    var keypad3: u8 = 'A';

    var list1: std.ArrayListUnmanaged([]u8) = .empty;
    var list2: std.ArrayListUnmanaged([]u8) = .empty;
    var list3: std.ArrayListUnmanaged([]u8) = .empty;

    var res: usize = 0;
    for (sample) |code| {
        keypad1 = 'A';
        keypad2 = 'A';
        keypad3 = 'A';
        list1.clearRetainingCapacity();
        list2.clearRetainingCapacity();
        list3.clearRetainingCapacity();
        try typeCode(allocator, code, &keypad1, &keypad2, &keypad3, &list1, &list2, &list3);
        const moves3 = try listToString(allocator, &list3);

        const code_number = try std.fmt.parseInt(usize, code[0..3], 10);
        const complexity = code_number * moves3.len;
        print("\n\nCode: {s}, Complexity: {d} [{d}, {d}]\n", .{ code, complexity, code_number, moves3.len });
        res += complexity;
    }

    print("Result: {d}\n\n\n", .{res});
    try testing.expect(res == 126384);
}

test "sample full part 2" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sample: [5][]const u8 = .{ "029A", "980A", "179A", "456A", "379A" };

    var memo: std.AutoArrayHashMapUnmanaged([3]u8, u64) = .empty;
    const max_robots: u8 = 2;

    var res: usize = 0;
    for (sample) |code| {
        memo.clearRetainingCapacity();

        var k1: u8 = 'A';
        var buffer = try allocator.alloc(u8, max_robots);
        for (0..buffer.len) |i| buffer[i] = 'A';
        const current: u8 = 0;

        var code_res: u64 = 0;
        for (code) |char| {
            const steps1 = try findStepsDigits(allocator, char, &k1);
            for (steps1) |step| {
                const partial = try findStepsRecursive(allocator, step, &buffer, current, max_robots, &memo);
                code_res += partial;
            }
        }

        const code_number = try std.fmt.parseInt(u64, code[0..3], 10);
        const complexity = code_number * code_res;
        print("\n\nPART 2: Code: {s}, Complexity: {d} [{d}, {d}]\n", .{ code, complexity, code_number, code_res });
        res += complexity;
    }

    print("\nResult Sample 2: {d}\n", .{res});
    try testing.expect(res == 126384);
}
