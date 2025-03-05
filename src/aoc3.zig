const std = @import("std");
const testing = std.testing;

pub fn find_next(c: u8) []const u8 {
    const next: []const u8 = switch (c) {
        'm' => "u",
        'u' => "l",
        'l' => "(",
        ',' => "0123456789",
        '0'...'9' => "0123456789,)",
        'd' => "o",
        'o' => "(n",
        'n' => "\'",
        '\'' => "t",
        't' => "(",
        '(' => "0123456789)",
        else => "md",
    };

    return next;
}

pub fn is_compatible(char: u8, candidates: []const u8) bool {
    for (candidates) |c| {
        if (c == char) {
            return true;
        }
    }
    return false;
}

pub fn calc_op(buff: []const u8) u32 {
    var buf1 = [1]u8{0} ** 3;
    var buf2 = [1]u8{0} ** 3;
    var pos1: u8 = 0;
    var pos2: u8 = 0;
    var add_num1: bool = true;
    for (buff[4..]) |c| {
        if (c == ')') break;
        if (c == ',') {
            add_num1 = false;
            continue;
        }
        if (add_num1) {
            buf1[pos1] = c;
            pos1 += 1;
        } else {
            buf2[pos2] = c;
            pos2 += 1;
        }
    }
    // std.debug.print("num1 {s}  num2 {s}  ", .{ buf1, buf2 });
    const num1 = std.fmt.parseUnsigned(u32, buf1[0..pos1], 10) catch 0;
    const num2 = std.fmt.parseUnsigned(u32, buf2[0..pos2], 10) catch 0;
    // std.debug.print("num1 {d}  num2 {d}  ", .{ num1, num2 });
    const result: u32 = num1 * num2;
    // std.debug.print("res {d}", .{result});
    return result;
}

pub fn read_seq(seq: []const u8) u32 {
    var buff = [1]u8{undefined} ** 12;
    var pos: u8 = 0;
    var next: []const u8 = "md";

    var sum: u32 = 0;
    var enabled: bool = true;
    for (seq) |char| {
        if (is_compatible(char, next)) {
            // std.debug.print("CHAR: {c}\n", .{char});
            // std.debug.print("BUFFER: {s}\n", .{buff});
            buff[pos] = char;
            pos += 1;
            next = find_next(char);
            // std.debug.print("NEXT: {any}\n", .{next});
        } else {
            buff = [1]u8{undefined} ** 12;
            pos = 0;
            next = "md";
            continue;
        }
        if (char == ')') {
            // std.debug.print("{s}\n", .{buff});
            if (std.mem.eql(u8, buff[0..3], "don"[0..3])) {
                enabled = false;
                // std.debug.print("BUFFER DONT: {s}\n", .{buff});
            } else if (std.mem.eql(u8, buff[0..3], "do("[0..3])) {
                enabled = true;
                // std.debug.print("BUFFER DO: {s}\n", .{buff});
            } else {
                if (enabled) {
                    // std.debug.print("BUFFER SUM: {s}\n", .{buff});

                    sum += calc_op(&buff);
                }
            }
            buff = [1]u8{undefined} ** 12;
            pos = 0;
            next = "md";
        }
    }
    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("src/inputs/input3.txt", .{});
    const read_buf = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(read_buf);

    const result = read_seq(read_buf);

    std.debug.print("Results: {d}\n", .{result});
}

test "calculate" {
    try testing.expect(calc_op("mul(5,5)") == 25);
    try testing.expect(calc_op("mul(2,22)") == 44);
    try testing.expect(calc_op("mul(10,2)") == 20);
    try testing.expect(calc_op("mul(10,22)") == 220);
    try testing.expect(calc_op("mul(10,333)") == 3330);
    try testing.expect(calc_op("mul(100,333)") == 33300);
}

// test "compatible" {
//     try testing.expect(is_compatible(
//         '2',
//         Nexts{ .num = [10]u8{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' } },
//     ));
// }

test "compatible" {
    try testing.expect(is_compatible(
        '2',
        [10]u8{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' },
    ));
}

test "example" {
    const sample = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    const res = read_seq(sample);
    try testing.expect(res == (8 + 25 + 88 + 40));
}

test "example2" {
    const sample = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    const res = read_seq(sample);
    std.debug.print("Results: {d}\n", .{res});
    try testing.expect(res == 48);
}
