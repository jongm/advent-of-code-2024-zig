const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const input = @embedFile("inputs/input02.txt");

pub fn checkSlice(slice: []i32) bool {
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

pub fn checkReport(slice: []i32, depth: u8) bool {
    if (depth == 0) {
        return checkSlice(slice);
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
            const new_res: bool = checkReport(num_buffer[0..pos], depth - 1);
            res = res or new_res;
        }
        return res;
    }
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();

    var safes: u16 = 0;
    var safes2: u16 = 0;

    var iterator = std.mem.splitScalar(u8, input, '\n');
    while (iterator.next()) |line| {
        if (line.len == 0) break;
        var nums = std.mem.splitSequence(u8, line, " ");
        var slice: std.ArrayListUnmanaged(i32) = .empty;
        defer slice.deinit(allocator);

        while (nums.next()) |num| {
            const nump = try std.fmt.parseUnsigned(i32, num, 10);
            try slice.append(allocator, nump);
        }

        if (checkReport(slice.items, 0)) safes += 1;
        if (checkReport(slice.items, 1)) safes2 += 1;
    }

    std.debug.print("Safe reports: {d}\n", .{safes});
    std.debug.print("Safe reports part 2: {d}\n", .{safes2});
}

test "safe0" {
    var nums1 = [_]i32{ 10, 12, 13, 14, 15 };
    try testing.expect(checkReport(&nums1, 0));
    var nums2 = [_]i32{ 20, 19, 18, 17, 16 };
    try testing.expect(checkReport(&nums2, 0));

    var nums3 = [_]i32{ 10, 12, 13, 14, 15 };
    try testing.expect(checkReport(&nums3, 0));
    var nums4 = [_]i32{ 20, 19, 18, 17, 16 };
    try testing.expect(checkReport(&nums4, 0));

    var nums5 = [_]i32{ 10, 11, 12, 13, 14 };
    try testing.expect(checkReport(&nums5, 0));
    var nums6 = [_]i32{ 10, 8, 7, 6, 5 };
    try testing.expect(checkReport(&nums6, 0));
}

test "unsafe0_start" {
    var nums1 = [_]i32{ 5, 12, 13, 14, 15 };
    try testing.expect(!checkReport(&nums1, 0));
    var nums2 = [_]i32{ 25, 19, 18, 17, 16 };
    try testing.expect(!checkReport(&nums2, 0));

    var nums3 = [_]i32{ 12, 12, 13, 14, 15 };
    try testing.expect(!checkReport(&nums3, 0));
    var nums4 = [_]i32{ 19, 19, 18, 17, 16 };
    try testing.expect(!checkReport(&nums4, 0));

    var nums5 = [_]i32{ 12, 11, 12, 13, 14 };
    try testing.expect(!checkReport(&nums5, 0));
    var nums6 = [_]i32{ 7, 8, 7, 6, 5 };
    try testing.expect(!checkReport(&nums6, 0));
}

test "unsafe0_mid" {
    var nums1 = [_]i32{ 10, 12, 16, 14, 15 };
    try testing.expect(!checkReport(&nums1, 0));
    var nums2 = [_]i32{ 20, 19, 15, 17, 16 };
    try testing.expect(!checkReport(&nums2, 0));

    var nums3 = [_]i32{ 10, 12, 12, 13, 14 };
    try testing.expect(!checkReport(&nums3, 0));
    var nums4 = [_]i32{ 20, 19, 19, 17, 18 };
    try testing.expect(!checkReport(&nums4, 0));

    var nums5 = [_]i32{ 10, 11, 9, 10, 12 };
    try testing.expect(!checkReport(&nums5, 0));
    var nums6 = [_]i32{ 10, 8, 9, 7, 6 };
    try testing.expect(!checkReport(&nums6, 0));
}

test "unsafe0_end" {
    var nums1 = [_]i32{ 10, 12, 13, 14, 18 };
    try testing.expect(!checkReport(&nums1, 0));
    var nums2 = [_]i32{ 20, 19, 18, 17, 12 };
    try testing.expect(!checkReport(&nums2, 0));

    var nums3 = [_]i32{ 10, 12, 13, 14, 14 };
    try testing.expect(!checkReport(&nums3, 0));
    var nums4 = [_]i32{ 20, 19, 18, 17, 17 };
    try testing.expect(!checkReport(&nums4, 0));

    var nums5 = [_]i32{ 10, 11, 12, 13, 12 };
    try testing.expect(!checkReport(&nums5, 0));
    var nums6 = [_]i32{ 10, 8, 7, 6, 7 };
    try testing.expect(!checkReport(&nums6, 0));
}

test "safe1" {
    var nums1 = [_]i32{ 10, 12, 13, 20, 15 };
    try testing.expect(checkReport(&nums1, 1));
    var nums2 = [_]i32{ 20, 19, 18, 12, 16 };
    try testing.expect(checkReport(&nums2, 1));

    var nums3 = [_]i32{ 10, 6, 13, 14, 15 };
    try testing.expect(checkReport(&nums3, 1));
    var nums4 = [_]i32{ 20, 6, 18, 17, 16 };
    try testing.expect(checkReport(&nums4, 1));

    var nums5 = [_]i32{ 4, 11, 12, 13, 14 };
    try testing.expect(checkReport(&nums5, 1));
    var nums6 = [_]i32{ 4, 8, 7, 6, 5 };
    try testing.expect(checkReport(&nums6, 1));

    var nums7 = [_]i32{ 7, 10, 8, 10, 11 };
    try testing.expect(checkReport(&nums7, 1));
    var nums8 = [_]i32{ 29, 28, 27, 25, 26, 25, 22, 20 };
    try testing.expect(checkReport(&nums8, 1));
}

test "unsafe1_start" {
    var nums1 = [_]i32{ 5, 12, 13, 2, 15 };
    try testing.expect(!checkReport(&nums1, 1));
    var nums2 = [_]i32{ 25, 19, 18, 24, 16 };
    try testing.expect(!checkReport(&nums2, 1));

    var nums3 = [_]i32{ 12, 12, 13, 14, 14 };
    try testing.expect(!checkReport(&nums3, 1));
    var nums4 = [_]i32{ 19, 19, 18, 17, 17 };
    try testing.expect(!checkReport(&nums4, 1));

    var nums5 = [_]i32{ 12, 11, 12, 13, 12 };
    try testing.expect(!checkReport(&nums5, 1));
    var nums6 = [_]i32{ 7, 8, 7, 6, 7 };
    try testing.expect(!checkReport(&nums6, 1));
}

test "unsafe1_mid" {
    var nums1 = [_]i32{ 10, 12, 16, 18, 15 };
    try testing.expect(!checkReport(&nums1, 1));
    var nums2 = [_]i32{ 20, 19, 2, 3, 16 };
    try testing.expect(!checkReport(&nums2, 1));

    var nums3 = [_]i32{ 10, 12, 12, 13, 13 };
    try testing.expect(!checkReport(&nums3, 1));
    var nums4 = [_]i32{ 20, 19, 19, 17, 17 };
    try testing.expect(!checkReport(&nums4, 1));

    var nums5 = [_]i32{ 10, 11, 9, 10, 9 };
    try testing.expect(!checkReport(&nums5, 1));
    var nums6 = [_]i32{ 10, 8, 9, 7, 8 };
    try testing.expect(!checkReport(&nums6, 1));
}

test "unsafe1_end" {
    var nums1 = [_]i32{ 10, 12, 13, 20, 18 };
    try testing.expect(!checkReport(&nums1, 1));
    var nums2 = [_]i32{ 20, 19, 18, 5, 12 };
    try testing.expect(!checkReport(&nums2, 1));

    var nums3 = [_]i32{ 10, 12, 12, 14, 14 };
    try testing.expect(!checkReport(&nums3, 1));
    var nums4 = [_]i32{ 20, 19, 19, 17, 17 };
    try testing.expect(!checkReport(&nums4, 1));

    var nums5 = [_]i32{ 10, 11, 12, 10, 11 };
    try testing.expect(!checkReport(&nums5, 1));
    var nums6 = [_]i32{ 10, 8, 7, 8, 9 };
    try testing.expect(!checkReport(&nums6, 1));
}
