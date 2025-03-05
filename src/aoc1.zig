const std = @import("std");

// PART 2
pub fn isin(comptime T: type, value: T, list: []T) !bool {
    for (list) |el| {
        if (el == value) {
            return true;
        }
    }
    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input1.txt", .{});
    const read_buf = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(read_buf);

    var it = std.mem.splitScalar(u8, read_buf, '\n');

    var col1 = std.ArrayList(i32).init(allocator);
    var col2 = std.ArrayList(i32).init(allocator);
    defer col1.deinit();
    defer col2.deinit();

    while (it.next()) |line| {
        if (line.len == 0) {
            break;
        }
        // std.debug.print("{s}\n", .{line});
        var nums = std.mem.splitSequence(u8, line, "   ");
        const d1 = nums.next().?;
        const d2 = nums.next().?;

        const d1n = try std.fmt.parseUnsigned(i32, d1, 10);
        const d2n = try std.fmt.parseUnsigned(i32, d2, 10);

        try col1.append(d1n);
        try col2.append(d2n);
    }

    // std.debug.print("{d} - {d}\n", .{ col1.items.len, col2.items.len });
    // std.debug.print("{any}\n", .{@TypeOf(col1.items)});

    std.mem.sort(i32, col1.items, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, col2.items, {}, comptime std.sort.asc(i32));

    // std.debug.print("{any}\n", .{col1.items});

    var sum: i64 = 0;
    for (col1.items, col2.items) |num1, num2| {
        sum += @abs(num1 - num2);
    }
    std.debug.print("Results: {d}\n", .{sum});

    var exists = std.ArrayList(i32).init(allocator);
    defer exists.deinit();

    var sum2: i64 = 0;
    for (col1.items) |num1| {
        for (col2.items) |num2| {
            if (num1 == num2) {
                sum2 += num1;
            }
        }
    }
    std.debug.print("Results 2: {d}\n", .{sum2});
}

// pub fn main() !void {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     const file_content = try std.fs.cwd().readFileAlloc(gpa.allocator(), "input1.txt", std.math.maxInt(usize));
//     std.debug.print("{any}\n", .{@TypeOf(file_content)});
// }

// pub fn main() !void {
//     const file = try std.fs.cwd().openFile("input1.txt", .{});
//     defer file.close();
//     var rbuf = std.io.bufferedReader(file.reader());
//     var r = rbuf.reader();
//     var line_buffer: [32]u8 = undefined;
//     var counter: usize = 0;

//     var c1buf: [1024]i32 = [1]i32{0} ** 1024;
//     var c2buf: [1024]i32 = [1]i32{0} ** 1024;

//     while (true) : (counter += 1) {
//         const stream = try r.readUntilDelimiterOrEof(&line_buffer, '\n');
//         if (stream == null) {
//             break;
//         }
//         const line = stream.?;

//         var nums = std.mem.splitSequence(u8, line, "   ");
//         const d1 = nums.next().?;
//         const d2 = nums.next().?;
//         // std.debug.print("{any} - {any}\n", .{ @TypeOf(d1), @TypeOf(d2) });
//         // std.debug.print("{s} - {s}\n", .{ d1, d2 });

//         const d1n = try std.fmt.parseInt(i32, d1, 10);
//         const d2n = try std.fmt.parseInt(i32, d2, 10);

//         // std.debug.print("{any} - {any}\n", .{ @TypeOf(d1n), @TypeOf(d2n) });
//         // std.debug.print("{d} - {d}\n", .{ d1n, d2n });

//         c1buf[counter] = d1n;
//         c2buf[counter] = d2n;

//         // std.debug.print("Result: {d}\n", .{sum});
//         // if (counter >= 10) {
//         //     break;
//         // }
//     }

//     // var c1buf2: [counter]u32 = c1buf[0..counter];
//     // var c2buf2: [counter]u32 = c2buf[0..counter];

//     std.mem.sort(i32, &c1buf, {}, comptime std.sort.desc(i32));
//     std.mem.sort(i32, &c2buf, {}, comptime std.sort.desc(i32));
//     // std.debug.print("{any} - {any}\n", .{ c1buf, c2buf });

//     var sum: i64 = 0;
//     for (0..counter) |i| {
//         sum += @abs(c1buf[i] - c2buf[i]);
//     }
//     std.debug.print("Results: {d}", .{sum});
// }
