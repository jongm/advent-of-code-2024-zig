const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input13.txt");

pub fn checkMachine(target: [2]i128, a: [2]i128, b: [2]i128) ?[2]i128 {
    // Algebra
    const b_press = std.math.divExact(i128, (a[1] * target[0] - a[0] * target[1]), (a[1] * b[0] - a[0] * b[1])) catch return null;
    const remain_x: i128 = target[0] - b_press * b[0];
    const remain_y: i128 = target[1] - b_press * b[1];

    const a_press_x = std.math.divExact(i128, remain_x, a[0]) catch return null;
    const a_press_y = std.math.divExact(i128, remain_y, a[1]) catch return null;
    if (a_press_x != a_press_y) return null;

    return [2]i128{ a_press_x, b_press };
}

pub fn findBetween(string: []const u8, left: []const u8, right: []const u8, offset: usize) ?[]const u8 {
    const start = std.mem.indexOfPos(u8, string, offset, left);
    if (start == null) return null;
    const end = std.mem.indexOfPos(u8, string, start.?, right);
    if (end == null) return null;
    const start_ix = start.? + left.len;
    return string[start_ix..end.?];
}

pub fn parseRow(string: []const u8) !struct { target: [2]i128, a: [2]i128, b: [2]i128 } {
    const t_x = findBetween(string, "X=", ", Y=", 0).?;
    const t_y = findBetween(string, "Y=", "\n", 0).?;
    const a_x = findBetween(string, ": X+", ", Y+", 0).?;
    const a_y = findBetween(string, ", Y+", "\nB", 0).?;
    const b_x = findBetween(string, "B: X+", ", Y+", 0).?;
    const b_y = findBetween(string, ", Y+", "\nP", std.mem.indexOf(u8, string, "Button B").?).?;

    // print("PARSED: {s},{s}  {s},{s}  {s},{s}\n", .{ t_x, t_y, a_x, a_y, b_x, b_y });

    const t_x_n: i128 = try std.fmt.parseInt(i128, t_x, 10);
    const t_y_n: i128 = try std.fmt.parseInt(i128, t_y, 10);
    const a_x_n: i128 = try std.fmt.parseInt(i128, a_x, 10);
    const a_y_n: i128 = try std.fmt.parseInt(i128, a_y, 10);
    const b_x_n: i128 = try std.fmt.parseInt(i128, b_x, 10);
    const b_y_n: i128 = try std.fmt.parseInt(i128, b_y, 10);

    return .{ .target = [2]i128{ t_x_n, t_y_n }, .a = [2]i128{ a_x_n, a_y_n }, .b = [2]i128{ b_x_n, b_y_n } };
}

pub fn main() !void {
    var res: i128 = 0;
    var res2: i128 = 0;
    var iterator = std.mem.splitSequence(u8, raw, "Button A");
    _ = iterator.next();
    while (iterator.next()) |row| {
        // print("ROW: {any}", .{row});
        if (row.len == 0) break;
        var machine = try parseRow(row);
        const presses = checkMachine(machine.target, machine.a, machine.b);
        if (presses) |optim| {
            const cost: i128 = optim[0] * 3 + optim[1] * 1;
            res += cost;
        }
        machine.target[0] += 10_000_000_000_000;
        machine.target[1] += 10_000_000_000_000;
        const presses2 = checkMachine(machine.target, machine.a, machine.b);
        if (presses2) |optim2| {
            const cost2: i128 = optim2[0] * 3 + optim2[1] * 1;
            res2 += cost2;
        }
    }
    print("Result: {d}\n", .{res});
    print("Result 2: {d}\n", .{res2});
}

test "check_machines" {
    const optim1 = checkMachine([2]i128{ 8400, 5400 }, [2]i128{ 94, 34 }, [2]i128{ 22, 67 });
    // print("1: {any}\n", .{optim1});
    const cost1: i128 = optim1.?[0] * 3 + optim1.?[1] * 1;
    try testing.expect(cost1 == 280);

    const optim2 = checkMachine([2]i128{ 12748, 12176 }, [2]i128{ 26, 66 }, [2]i128{ 67, 21 });
    // print("1: {any}\n", .{optim2});
    try testing.expect(optim2 == null);

    const optim3 = checkMachine([2]i128{ 7870, 6450 }, [2]i128{ 17, 86 }, [2]i128{ 84, 37 });
    // print("1: {any}\n", .{optim3});
    const cost3: i128 = optim3.?[0] * 3 + optim3.?[1] * 1;
    try testing.expect(cost3 == 200);

    const optim4 = checkMachine([2]i128{ 18641, 10279 }, [2]i128{ 69, 23 }, [2]i128{ 27, 71 });
    // print("1: {any}\n", .{optim4});
    try testing.expect(optim4 == null);
}

test "check_machines2" {
    const optim1 = checkMachine([2]i128{ 10000000008400, 10000000005400 }, [2]i128{ 94, 34 }, [2]i128{ 22, 67 });
    // print("1: {any}\n", .{optim1});
    try testing.expect(optim1 == null);

    const optim2 = checkMachine([2]i128{ 10000000012748, 10000000012176 }, [2]i128{ 26, 66 }, [2]i128{ 67, 21 });
    // print("1: {any}\n", .{optim2});
    const cost2: i128 = optim2.?[0] * 3 + optim2.?[1] * 1;
    try testing.expect(cost2 > 0);

    const optim3 = checkMachine([2]i128{ 10000000007870, 10000000006450 }, [2]i128{ 17, 86 }, [2]i128{ 84, 37 });
    // print("1: {any}\n", .{optim3});
    try testing.expect(optim3 == null);

    const optim4 = checkMachine([2]i128{ 10000000018641, 10000000010279 }, [2]i128{ 69, 23 }, [2]i128{ 27, 71 });
    // print("1: {any}\n", .{optim4});
    const cost4: i128 = optim4.?[0] * 3 + optim4.?[1] * 1;
    try testing.expect(cost4 > 0);
}

test "finding" {
    const sample =
        \\Button A: X+54, Y+22
        \\Button B: X+36, Y+62
        \\Prize: X=19754, Y=14184
        \\
    ;

    const res = findBetween(sample, "B: X+", ", Y+", 0).?;
    print("RES: {s}\n", .{res});

    try testing.expectEqualStrings("36", res);
}

test "parsing" {
    const sample =
        \\Button A: X+54, Y+22
        \\Button B: X+36, Y+62
        \\Prize: X=19754, Y=14184
        \\
    ;

    const machine = try parseRow(sample);
    try testing.expect(std.mem.eql(i128, &machine.target, &[2]i128{ 19754, 14184 }));
    try testing.expect(std.mem.eql(i128, &machine.a, &[2]i128{ 54, 22 }));
    try testing.expect(std.mem.eql(i128, &machine.b, &[2]i128{ 36, 62 }));
}
