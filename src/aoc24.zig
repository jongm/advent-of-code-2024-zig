const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input24.txt");

fn sortStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

pub fn parseInstructions(allocator: std.mem.Allocator, string: []const u8, map: *std.ArrayListUnmanaged([4][]const u8)) !void {
    var row_iterator = std.mem.splitScalar(u8, string, '\n');
    while (row_iterator.next()) |row| {
        if (row.len == 0) break;
        var op_iterator = std.mem.splitScalar(u8, row, ' ');
        const gate1 = op_iterator.next().?;
        const op = op_iterator.next().?;
        const gate2 = op_iterator.next().?;
        _ = op_iterator.next().?;
        const target = op_iterator.next().?;
        try map.append(allocator, [4][]const u8{ gate1, gate2, op, target });
    }
}

const Operation = enum {
    OR,
    AND,
    XOR,
};

pub fn executeOperation(allocator: std.mem.Allocator, gatemap: *std.StringArrayHashMapUnmanaged(u1), op: [4][]const u8) !void {
    const gate1 = gatemap.get(op[0]).?;
    const gate2 = gatemap.get(op[1]).?;
    const operator = std.meta.stringToEnum(Operation, op[2]).?;
    const target = op[3];

    const result: u1 = switch (operator) {
        .OR => gate1 | gate2,
        .AND => gate1 & gate2,
        .XOR => gate1 ^ gate2,
    };

    try gatemap.put(allocator, target, result);
}

pub fn traverseWireBack(gate: []const u8, operations: std.ArrayListUnmanaged([4][]const u8)) []const u8 {
    if (gate[0] == 'z') return gate;
    for (operations.items) |op| {
        if (std.mem.eql(u8, op[0], gate) or std.mem.eql(u8, op[1], gate)) {
            return traverseWireBack(op[3], operations);
        }
    }
    return "000";
}

pub fn findWrongWires(operations: std.ArrayListUnmanaged([4][]const u8)) [6][]const u8 {
    // Implementing https://www.reddit.com/r/adventofcode/comments/1hla5ql/2024_day_24_part_2_a_guide_on_the_idea_behind_the/
    var results: [6][]const u8 = @splat("000");
    var index: usize = 0;
    for (operations.items) |op| {
        // First possible case
        if (op[3][0] == 'z') {
            if (!std.mem.eql(u8, op[3], "z45")) {
                if (!std.mem.eql(u8, op[2], "XOR")) {
                    results[index] = op[3];
                    index += 1;
                }
            }
            // Second possible case
        } else {
            if ((op[0][0] != 'x') and (op[0][0] != 'y') and (op[1][0] != 'x') and (op[1][0] != 'y')) {
                if (std.mem.eql(u8, op[2], "XOR")) {
                    results[index] = op[3];
                    index += 1;
                }
            }
        }
    }
    // Third possible cases
    return results;
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const allocator = debug_allocator.allocator();

    var gatemap: std.StringArrayHashMapUnmanaged(u1) = .empty;
    defer gatemap.deinit(allocator);

    var input_iterator = std.mem.splitSequence(u8, raw, "\n\n");
    const values = input_iterator.next().?;
    const instructions = input_iterator.next().?;

    var values_iter = std.mem.splitScalar(u8, values, '\n');
    while (values_iter.next()) |row| {
        if (row.len == 0) break;
        const key = row[0..3];
        const val = try std.fmt.parseInt(u1, row[5..6], 10);
        try gatemap.put(allocator, key, val);
    }
    var gatemap2 = try gatemap.clone(allocator);
    var operations: std.ArrayListUnmanaged([4][]const u8) = .empty;
    defer operations.deinit(allocator);
    try parseInstructions(allocator, instructions, &operations);

    mainloop: while (operations.items.len > 0) {
        for (operations.items, 0..) |oper, i| {
            if (gatemap.contains(oper[0]) and gatemap.contains(oper[1])) {
                try executeOperation(allocator, &gatemap, oper);
                _ = operations.swapRemove(i);
                continue :mainloop;
            }
        }
    }

    var res: u64 = 0;
    var key_buffer: [3]u8 = @splat(0);
    var count: usize = 0;
    while (true) {
        _ = try std.fmt.bufPrint(&key_buffer, "z{d:02}", .{count});
        const bit = gatemap.get(&key_buffer) orelse break;
        res += std.math.pow(u64, 2, @intCast(count)) * bit;
        count += 1;
    }
    print("Part 1: {d}, Max Z: {d}\n", .{ res, count - 1 });

    //Part 2
    try parseInstructions(allocator, instructions, &operations);
    const wrong_wires = findWrongWires(operations);
    var wrong_wires_nums: [3]u8 = undefined;
    var wr: u8 = 0;
    for (wrong_wires) |wire| {
        if (wire[0] == 'z') {
            const num = try std.fmt.parseInt(u8, wire[1..], 10);
            wrong_wires_nums[wr] = num;
            wr += 1;
        }
    }
    // print("Wrong: {s}\n", .{wrong_wires});

    var rewire_map = std.StringArrayHashMapUnmanaged([]const u8).empty;
    var wrong_wires_fix: [6][]const u8 = @splat("000");

    var n: u8 = 0;
    var match_fixes: [6][3]u8 = @splat([3]u8{ 0, 0, 0 });
    for (wrong_wires) |wire| {
        if (wire[0] != 'z') {
            const match = traverseWireBack(wire, operations);
            const match_num = try std.fmt.parseInt(u8, match[1..3], 10);
            var use_num: u8 = 0;
            var dif: u8 = 255;
            for (wrong_wires_nums) |num| {
                if (num > match_num) continue;
                const new_dif: u8 = match_num - num;
                if (new_dif < dif) {
                    use_num = num;
                    dif = new_dif;
                }
            }
            _ = try std.fmt.bufPrint(&match_fixes[n], "z{d}", .{use_num});
            try rewire_map.put(allocator, wire, &match_fixes[n]);
            try rewire_map.put(allocator, &match_fixes[n], wire);
            // print("From {s} we go to {s} fixed as {s}\n", .{ wire, match, match_fixes[n] });
            wrong_wires_fix[n * 2] = wire;
            wrong_wires_fix[n * 2 + 1] = &match_fixes[n];
            n += 1;
        }
    }
    // print("Fixes: {s}\n", .{wrong_wires_fix});

    // Correct the first 6 wrong wires
    fixloop: for (wrong_wires_fix) |wire| {
        for (operations.items, 0..) |op, i| {
            if (std.mem.eql(u8, op[3], wire)) {
                const new_op = [4][]const u8{ op[0], op[1], op[2], rewire_map.get(wire).? };
                // print("Swap {s} to {s}\n", .{ op[3], rewire_map.get(wire).? });
                _ = operations.swapRemove(i);
                try operations.append(allocator, new_op);
                continue :fixloop;
            }
        }
    }

    mainloop2: while (operations.items.len > 0) {
        for (operations.items, 0..) |oper, i| {
            if (gatemap2.contains(oper[0]) and gatemap2.contains(oper[1])) {
                // print("Oper {s}\n", .{oper});
                try executeOperation(allocator, &gatemap2, oper);
                _ = operations.swapRemove(i);
                continue :mainloop2;
            }
        }
        print("Remain {d}\n", .{operations.items.len});
        break;
    }

    var res2: u64 = 0;
    count = 0;
    while (true) {
        _ = try std.fmt.bufPrint(&key_buffer, "z{d:02}", .{count});
        const bit = gatemap2.get(&key_buffer) orelse break;
        res2 += std.math.pow(u64, 2, @intCast(count)) * bit;
        count += 1;
    }
    var x: u45 = 0;
    var y: u45 = 0;
    var xbuff: [3]u8 = @splat(0);
    var ybuff: [3]u8 = @splat(0);
    for (0..45) |i| {
        _ = try std.fmt.bufPrint(&xbuff, "x{d:02}", .{i});
        _ = try std.fmt.bufPrint(&ybuff, "y{d:02}", .{i});
        const bitx = gatemap.get(&xbuff).?;
        const bity = gatemap.get(&ybuff).?;
        x += std.math.pow(u45, 2, @intCast(i)) * bitx;
        y += std.math.pow(u45, 2, @intCast(i)) * bity;
    }
    // const real_result: u64 = try std.math.add(u64, x, y);
    // print("Result 2 Partial: {d}\n", .{res2});
    // print("Result 2 Real: {d}\n", .{real_result});
    // const res_xor = real_result ^ res2;
    // print("XOR: {b}\n", .{res_xor});

    // Count leading zeros and put here:
    // exmplae: 11000000000000000000000000000
    const zeros = "27";
    print("\n\nHardcoding amount fo zeros, {s} in my case. Use yours!!\n\n", .{zeros});

    try parseInstructions(allocator, instructions, &operations);
    var all_fixes: [8][]const u8 = undefined;
    var i: usize = 0;
    for (operations.items) |op| {
        if (std.mem.eql(u8, op[0][1..], zeros) or std.mem.eql(u8, op[1][1..], zeros)) {
            // print("Operation with error: {s}\n", .{op});
            all_fixes[i] = op[3];
            i += 1;
        }
    }
    for (wrong_wires_fix) |fix| {
        all_fixes[i] = fix;
        i += 1;
    }
    // print("Final Fixes: {s}\n", .{all_fixes});
    std.mem.sort([]const u8, &all_fixes, {}, sortStrings);
    print("Part 2: ", .{});
    for (all_fixes) |fix| {
        print("{s},", .{fix});
    }
}

test "sample" {
    const values =
        \\x00: 1
        \\x01: 0
        \\x02: 1
        \\x03: 1
        \\x04: 0
        \\y00: 1
        \\y01: 1
        \\y02: 1
        \\y03: 1
        \\y04: 1
    ;
    const instructions =
        \\ntg XOR fgs -> mjb
        \\y02 OR x01 -> tnw
        \\kwq OR kpj -> z05
        \\x00 OR x03 -> fst
        \\tgd XOR rvg -> z01
        \\vdt OR tnw -> bfw
        \\bfw AND frj -> z10
        \\ffh OR nrd -> bqk
        \\y00 AND y03 -> djm
        \\y03 OR y00 -> psh
        \\bqk OR frj -> z08
        \\tnw OR fst -> frj
        \\gnj AND tgd -> z11
        \\bfw XOR mjb -> z00
        \\x03 OR x00 -> vdt
        \\gnj AND wpb -> z02
        \\x04 AND y00 -> kjc
        \\djm OR pbm -> qhw
        \\nrd AND vdt -> hwm
        \\kjc AND fst -> rvg
        \\y04 OR y02 -> fgs
        \\y01 AND x02 -> pbm
        \\ntg OR kjc -> kwq
        \\psh XOR fgs -> tgd
        \\qhw XOR tgd -> z09
        \\pbm OR djm -> kpj
        \\x03 XOR y03 -> ffh
        \\x00 XOR y04 -> ntg
        \\bfw OR bqk -> z06
        \\nrd XOR fgs -> wpb
        \\frj XOR qhw -> z04
        \\bqk OR frj -> z07
        \\y03 OR x01 -> nrd
        \\hwm AND bqk -> z03
        \\tgd XOR rvg -> z12
        \\tnw OR pbm -> gnj
    ;

    const allocator = testing.allocator;

    var gatemap: std.StringArrayHashMapUnmanaged(u1) = .empty;
    defer gatemap.deinit(allocator);

    var values_iter = std.mem.splitScalar(u8, values, '\n');
    while (values_iter.next()) |row| {
        if (row.len == 0) break;
        const key = row[0..3];
        const val = try std.fmt.parseInt(u1, row[5..6], 10);
        try gatemap.put(allocator, key, val);
    }

    var operations: std.ArrayListUnmanaged([4][]const u8) = .empty;
    defer operations.deinit(allocator);
    try parseInstructions(allocator, instructions, &operations);

    // for (operations.items) |item| {
    //     print("{s}\n", .{item});
    // }
    mainloop: while (operations.items.len > 0) {
        for (operations.items, 0..) |oper, i| {
            if (gatemap.contains(oper[0]) and gatemap.contains(oper[1])) {
                try executeOperation(allocator, &gatemap, oper);
                _ = operations.swapRemove(i);
                continue :mainloop;
            }
        }
    }

    var res: u64 = 0;
    var key_buffer: [3]u8 = @splat(0);
    var count: usize = 0;
    while (true) {
        _ = try std.fmt.bufPrint(&key_buffer, "z{d:02}", .{count});
        const bit = gatemap.get(&key_buffer) orelse break;
        res += std.math.pow(u64, 2, @intCast(count)) * bit;
        count += 1;
    }
    print("Result: {d}\n", .{res});
    try testing.expect(res == 2024);
}
