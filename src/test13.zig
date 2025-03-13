const std = @import("std");
const testing = std.testing;

const raw = @embedFile("inputs/input13.txt");

pub fn main() void {}

pub fn checkMachine(target: [2]i64, a: [2]i64, b: [2]i64) ?[2]i64 {
    // Algebra
    const b_press = std.math.divExact(i64, (a[1] * target[0] - a[0] * target[1]), (a[1] * b[0] - a[0] * b[1])) catch return null;
    const remain_x: i64 = target[0] - b_press * b[0];
    const remain_y: i64 = target[1] - b_press * b[1];

    const a_press_x = std.math.divExact(i64, remain_x, a[0]) catch return null;
    const a_press_y = std.math.divExact(i64, remain_y, a[1]) catch return null;
    if (a_press_x != a_press_y) return null;

    return [2]i64{ a_press_x, b_press };
}

test "check_machines" {
    const optim1 = checkMachine([2]i64{ 8400, 5400 }, [2]i64{ 94, 34 }, [2]i64{ 22, 67 });
    // std.debug.print("1: {any}\n", .{optim1});
    const cost1: i64 = optim1.?[0] * 3 + optim1.?[1] * 1;
    try testing.expect(cost1 == 280);

    const optim2 = checkMachine([2]i64{ 12748, 12176 }, [2]i64{ 26, 66 }, [2]i64{ 67, 21 });
    // std.debug.print("1: {any}\n", .{optim2});
    try testing.expect(optim2 == null);

    const optim3 = checkMachine([2]i64{ 7870, 6450 }, [2]i64{ 17, 86 }, [2]i64{ 84, 37 });
    // std.debug.print("1: {any}\n", .{optim3});
    const cost3: i64 = optim3.?[0] * 3 + optim3.?[1] * 1;
    try testing.expect(cost3 == 200);

    const optim4 = checkMachine([2]i64{ 18641, 10279 }, [2]i64{ 69, 23 }, [2]i64{ 27, 71 });
    // std.debug.print("1: {any}\n", .{optim4});
    try testing.expect(optim4 == null);
}
