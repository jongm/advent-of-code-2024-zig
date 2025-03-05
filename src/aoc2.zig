const std = @import("std");
const testing = std.testing;

pub fn check_slice(slice: []i32) bool {
    var prev: i32 = undefined;
    var inc: bool = undefined;
    var leng: u8 = 0;

    for (slice, 0..) |nump, i| {
        if (i == 0) {
            prev = nump;
            leng += 1;
            continue;
        }
        if ((@abs(prev - nump) == 0) or (@abs(prev - nump) > 3)) {
            return false;
        }
        if (leng >= 2) {
            const inc_now: bool = (nump - prev) > 0;
            if (inc_now != inc) {
                return false;
            }
        }

        inc = (nump - prev) > 0;
        prev = nump;
        leng += 1;
    }
    return true;
}

pub fn check_report(slice: []i32, depth: u8) bool {
    if (depth == 0) {
        return check_slice(slice);
    } else {
        var res: bool = false;
        const slice_size = slice.len;
        for (0..slice_size) |i| {
            var num_buffer: [32]i32 = undefined;
            var pos: u8 = 0;
            for (slice, 0..) |num, n| {
                if (n != i) {
                    num_buffer[pos] = num;
                    pos += 1;
                }
            }
            const new_res: bool = check_report(num_buffer[0..pos], depth - 1);
            res = res or new_res;
        }
        return res;
    }
}

// pub fn check_report(slice: []i32, max_damp: u8) bool {
//     if (max_damp == 0) {
//         if (check_slice(slice)) {
//             return true;
//         }
//     } else {
//         const max = slice.len;
//         for (0..max) |i| {
//             var num_buffer: [32]i32 = undefined;
//             var pos: u8 = 0;
//             for (slice, 0..) |num, n| {
//                 if (n != i) {
//                     num_buffer[pos] = num;
//                     pos += 1;
//                 }
//             }
//             if (check_slice(num_buffer[0..pos])) {
//                 return true;
//             }
//         }
//     }
//     return false;
// }

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input2.txt", .{});
    defer file.close();
    var rbuf = std.io.bufferedReader(file.reader());
    var r = rbuf.reader();

    var line_buffer: [32]u8 = undefined;
    var safes: u16 = 0;

    const max_damp: u8 = 1;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    mainloop: while (true) {
        const stream = try r.readUntilDelimiterOrEof(&line_buffer, '\n');
        if (stream == null) {
            break;
        }
        const line = stream.?;
        var nums = std.mem.splitSequence(u8, line, " ");
        var slice = std.ArrayList(i32).init(allocator);
        defer slice.deinit();

        while (nums.next()) |num| {
            const nump = std.fmt.parseUnsigned(i32, num, 10) catch |err| {
                std.debug.print("Safe reports: {any}", .{num});
                std.debug.print("Safe reports: {any}", .{err});
                continue :mainloop;
            };
            try slice.append(nump);
        }

        if (check_report(slice.items, max_damp)) {
            safes += 1;
        }
    }

    std.debug.print("Safe reports: {d}", .{safes});
}

test "safe0" {
    var nums1 = [_]i32{ 10, 12, 13, 14, 15 };
    try testing.expect(check_report(&nums1, 0));
    var nums2 = [_]i32{ 20, 19, 18, 17, 16 };
    try testing.expect(check_report(&nums2, 0));

    var nums3 = [_]i32{ 10, 12, 13, 14, 15 };
    try testing.expect(check_report(&nums3, 0));
    var nums4 = [_]i32{ 20, 19, 18, 17, 16 };
    try testing.expect(check_report(&nums4, 0));

    var nums5 = [_]i32{ 10, 11, 12, 13, 14 };
    try testing.expect(check_report(&nums5, 0));
    var nums6 = [_]i32{ 10, 8, 7, 6, 5 };
    try testing.expect(check_report(&nums6, 0));
}

test "unsafe0_start" {
    var nums1 = [_]i32{ 5, 12, 13, 14, 15 };
    try testing.expect(!check_report(&nums1, 0));
    var nums2 = [_]i32{ 25, 19, 18, 17, 16 };
    try testing.expect(!check_report(&nums2, 0));

    var nums3 = [_]i32{ 12, 12, 13, 14, 15 };
    try testing.expect(!check_report(&nums3, 0));
    var nums4 = [_]i32{ 19, 19, 18, 17, 16 };
    try testing.expect(!check_report(&nums4, 0));

    var nums5 = [_]i32{ 12, 11, 12, 13, 14 };
    try testing.expect(!check_report(&nums5, 0));
    var nums6 = [_]i32{ 7, 8, 7, 6, 5 };
    try testing.expect(!check_report(&nums6, 0));
}

test "unsafe0_mid" {
    var nums1 = [_]i32{ 10, 12, 16, 14, 15 };
    try testing.expect(!check_report(&nums1, 0));
    var nums2 = [_]i32{ 20, 19, 15, 17, 16 };
    try testing.expect(!check_report(&nums2, 0));

    var nums3 = [_]i32{ 10, 12, 12, 13, 14 };
    try testing.expect(!check_report(&nums3, 0));
    var nums4 = [_]i32{ 20, 19, 19, 17, 18 };
    try testing.expect(!check_report(&nums4, 0));

    var nums5 = [_]i32{ 10, 11, 9, 10, 12 };
    try testing.expect(!check_report(&nums5, 0));
    var nums6 = [_]i32{ 10, 8, 9, 7, 6 };
    try testing.expect(!check_report(&nums6, 0));
}

test "unsafe0_end" {
    var nums1 = [_]i32{ 10, 12, 13, 14, 18 };
    try testing.expect(!check_report(&nums1, 0));
    var nums2 = [_]i32{ 20, 19, 18, 17, 12 };
    try testing.expect(!check_report(&nums2, 0));

    var nums3 = [_]i32{ 10, 12, 13, 14, 14 };
    try testing.expect(!check_report(&nums3, 0));
    var nums4 = [_]i32{ 20, 19, 18, 17, 17 };
    try testing.expect(!check_report(&nums4, 0));

    var nums5 = [_]i32{ 10, 11, 12, 13, 12 };
    try testing.expect(!check_report(&nums5, 0));
    var nums6 = [_]i32{ 10, 8, 7, 6, 7 };
    try testing.expect(!check_report(&nums6, 0));
}

test "safe1" {
    var nums1 = [_]i32{ 10, 12, 13, 20, 15 };
    try testing.expect(check_report(&nums1, 1));
    var nums2 = [_]i32{ 20, 19, 18, 12, 16 };
    try testing.expect(check_report(&nums2, 1));

    var nums3 = [_]i32{ 10, 6, 13, 14, 15 };
    try testing.expect(check_report(&nums3, 1));
    var nums4 = [_]i32{ 20, 6, 18, 17, 16 };
    try testing.expect(check_report(&nums4, 1));

    var nums5 = [_]i32{ 4, 11, 12, 13, 14 };
    try testing.expect(check_report(&nums5, 1));
    var nums6 = [_]i32{ 4, 8, 7, 6, 5 };
    try testing.expect(check_report(&nums6, 1));

    var nums7 = [_]i32{ 7, 10, 8, 10, 11 };
    try testing.expect(check_report(&nums7, 1));
    var nums8 = [_]i32{ 29, 28, 27, 25, 26, 25, 22, 20 };
    try testing.expect(check_report(&nums8, 1));
}

test "unsafe1_start" {
    var nums1 = [_]i32{ 5, 12, 13, 2, 15 };
    try testing.expect(!check_report(&nums1, 1));
    var nums2 = [_]i32{ 25, 19, 18, 24, 16 };
    try testing.expect(!check_report(&nums2, 1));

    var nums3 = [_]i32{ 12, 12, 13, 14, 14 };
    try testing.expect(!check_report(&nums3, 1));
    var nums4 = [_]i32{ 19, 19, 18, 17, 17 };
    try testing.expect(!check_report(&nums4, 1));

    var nums5 = [_]i32{ 12, 11, 12, 13, 12 };
    try testing.expect(!check_report(&nums5, 1));
    var nums6 = [_]i32{ 7, 8, 7, 6, 7 };
    try testing.expect(!check_report(&nums6, 1));
}

test "unsafe1_mid" {
    var nums1 = [_]i32{ 10, 12, 16, 18, 15 };
    try testing.expect(!check_report(&nums1, 1));
    var nums2 = [_]i32{ 20, 19, 2, 3, 16 };
    try testing.expect(!check_report(&nums2, 1));

    var nums3 = [_]i32{ 10, 12, 12, 13, 13 };
    try testing.expect(!check_report(&nums3, 1));
    var nums4 = [_]i32{ 20, 19, 19, 17, 17 };
    try testing.expect(!check_report(&nums4, 1));

    var nums5 = [_]i32{ 10, 11, 9, 10, 9 };
    try testing.expect(!check_report(&nums5, 1));
    var nums6 = [_]i32{ 10, 8, 9, 7, 8 };
    try testing.expect(!check_report(&nums6, 1));
}

test "unsafe1_end" {
    var nums1 = [_]i32{ 10, 12, 13, 20, 18 };
    try testing.expect(!check_report(&nums1, 1));
    var nums2 = [_]i32{ 20, 19, 18, 5, 12 };
    try testing.expect(!check_report(&nums2, 1));

    var nums3 = [_]i32{ 10, 12, 12, 14, 14 };
    try testing.expect(!check_report(&nums3, 1));
    var nums4 = [_]i32{ 20, 19, 19, 17, 17 };
    try testing.expect(!check_report(&nums4, 1));

    var nums5 = [_]i32{ 10, 11, 12, 10, 11 };
    try testing.expect(!check_report(&nums5, 1));
    var nums6 = [_]i32{ 10, 8, 7, 8, 9 };
    try testing.expect(!check_report(&nums6, 1));
}

// pub fn check_slice(nums: anytype, max_damp: u8) bool {
//     var prev: i32 = undefined;
//     var inc: bool = undefined;
//     var i: u8 = 0;
//     var damp: u8 = 0;
//     var leng: u8 = 0;

//     while (nums.next()) |num| : (i += 1) {
//         const nump = std.fmt.parseUnsigned(i32, num, 10) catch |err| {
//             std.debug.print("Safe reports: {any}", .{num});
//             std.debug.print("Safe reports: {any}", .{err});
//             return false;
//         };

//         if (i == 0) {
//             prev = nump;
//             leng += 1;
//             continue;
//         }
//         if ((@abs(prev - nump) == 0) or (@abs(prev - nump) > 3)) {
//             if (damp >= max_damp) {
//                 return false;
//             }
//             damp += 1;
//             continue;
//         }
//         if (leng >= 2) {
//             const inc_now: bool = (nump - prev) > 0;
//             if (inc_now != inc) {
//                 if (damp >= max_damp) {
//                     return false;
//                 }
//                 damp += 1;
//                 continue;
//             }
//         }

//         inc = (nump - prev) > 0;
//         prev = nump;
//         leng += 1;
//     }
//     return true;
// }
