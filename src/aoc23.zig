const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input23.txt");

pub fn main() !void {
    var debugalloc = std.heap.DebugAllocator(.{}).init;
    var arena = std.heap.ArenaAllocator.init(debugalloc.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    var lan_map: std.StringHashMapUnmanaged(std.ArrayListUnmanaged([]const u8)) = .empty;

    var iterator = std.mem.splitScalar(u8, raw, '\n');
    while (iterator.next()) |row| {
        if (row.len == 0) break;
        try parsePairs(allocator, row, &lan_map);
    }

    const trios = try findTrios(allocator, &lan_map);

    var start_with_t: u32 = 0;
    for (trios.items) |trio| {
        for (trio) |pc| {
            if (pc[0] == 't') {
                start_with_t += 1;
                break;
            }
        }
    }

    print("Result: {d}\n", .{start_with_t});

    const current: std.ArrayListUnmanaged([]const u8) = .empty;
    const checked: std.ArrayListUnmanaged([]const u8) = .empty;
    var possible: std.ArrayListUnmanaged([]const u8) = .empty;
    var key_iter = lan_map.keyIterator();
    while (key_iter.next()) |key| {
        try possible.append(allocator, key.*);
    }
    var cliques: std.ArrayListUnmanaged(std.ArrayListUnmanaged([]const u8)) = .empty;

    try bronKerbosch(allocator, &lan_map, current, possible, checked, &cliques);

    var res2: usize = 0;
    var index2: usize = 0;
    for (cliques.items, 0..) |clique, i| {
        if (clique.items.len > res2) {
            res2 = clique.items.len;
            index2 = i;
        }
    }
    const biggest = cliques.items[index2].items;
    std.mem.sort([]const u8, biggest, {}, sortStrings);
    print("Result 2: ", .{});
    for (biggest) |node| {
        print("{s},", .{node});
    }
}

pub fn parsePairs(allocator: std.mem.Allocator, pair: []const u8, map: *std.StringHashMapUnmanaged(std.ArrayListUnmanaged([]const u8))) !void {
    const a = pair[0..2];
    const b = pair[3..5];

    const list1_ptr = try map.getOrPutValue(allocator, a, std.ArrayListUnmanaged([]const u8).empty);
    try list1_ptr.value_ptr.append(allocator, b);
    const list2_ptr = try map.getOrPutValue(allocator, b, std.ArrayListUnmanaged([]const u8).empty);
    try list2_ptr.value_ptr.append(allocator, a);
}
fn sortStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

pub fn compareStrings(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    for (a, b) |a_elem, b_elem| {
        if (a_elem != b_elem) return false;
    }
    return true;
}

pub fn compareSets(comptime len: u8, a: [len][]const u8, b: [len][]const u8) bool {
    for (a, b) |a_elem, b_elem| {
        if (!compareStrings(a_elem, b_elem)) return false;
    }
    return true;
}

pub fn listContains(comptime T: type, list: std.ArrayListUnmanaged(T), target: T) bool {
    for (list.items) |item| {
        if (compareStrings(item, target)) return true;
    }
    return false;
}

pub fn findTrios(allocator: std.mem.Allocator, map: *std.StringHashMapUnmanaged(std.ArrayListUnmanaged([]const u8))) !std.ArrayListUnmanaged([3][]const u8) {
    var trio_list: std.ArrayListUnmanaged([3][]const u8) = .empty;
    defer trio_list.deinit(allocator);
    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        const item1 = entry.key_ptr.*;
        for (entry.value_ptr.items) |item2| {
            mainloop: for (entry.value_ptr.items) |item3| {
                if (std.mem.eql(u8, item2, item3)) continue;
                for (map.get(item2).?.items) |item2pair| {
                    if (std.mem.eql(u8, item3, item2pair)) {
                        var trio = [3][]const u8{ item1, item2, item3 };
                        std.mem.sort([]const u8, &trio, {}, sortStrings);
                        try trio_list.append(allocator, trio);
                        continue :mainloop;
                    }
                }
            }
        }
    }
    var trio_list_dedup: std.ArrayListUnmanaged([3][]const u8) = .empty;
    trio: for (trio_list.items) |trio| {
        for (trio_list_dedup.items) |dedup| {
            if (compareSets(3, trio, dedup)) continue :trio;
        }
        try trio_list_dedup.append(allocator, trio);
    }

    return trio_list_dedup;
}

pub fn bronKerbosch(allocator: std.mem.Allocator, map: *std.StringHashMapUnmanaged(std.ArrayListUnmanaged([]const u8)), current_orig: std.ArrayListUnmanaged([]const u8), possible_orig: std.ArrayListUnmanaged([]const u8), checked_orig: std.ArrayListUnmanaged([]const u8), cliques: *std.ArrayListUnmanaged(std.ArrayListUnmanaged([]const u8))) !void {
    if ((possible_orig.items.len == 0) and (checked_orig.items.len == 0)) {
        if (current_orig.items.len >= 2) {
            try cliques.append(allocator, current_orig);
        }
    }
    // print("Running with {s} \n)", .{possible_orig.items});
    var possible = try possible_orig.clone(allocator);
    var checked = try checked_orig.clone(allocator);

    while (possible.items.len > 0) {
        const new = possible.pop().?;
        // print("Choosing {s} \n)", .{new});
        var current = try current_orig.clone(allocator);
        try current.append(allocator, new);

        var possible_next = try possible.clone(allocator);
        remove_loop_pos: while (true) { // Interesection of Possible and New Neighbors
            for (possible_next.items, 0..) |item, i| {
                if (!listContains([]const u8, map.get(new).?, item)) {
                    _ = possible_next.swapRemove(i);
                    continue :remove_loop_pos;
                }
            }
            break;
        }
        var checked_next = try checked.clone(allocator);
        remove_loop_che: while (true) { // Interesection of Checked and New Neighbors
            for (checked_next.items, 0..) |item, i| {
                if (!listContains([]const u8, map.get(new).?, item)) {
                    _ = checked_next.swapRemove(i);
                    continue :remove_loop_che;
                }
            }
            break;
        }
        try bronKerbosch(allocator, map, current, possible_next, checked_next, cliques);
        try checked.append(allocator, new);
    }
}

test "sample" {
    const samples =
        \\kh-tc
        \\qp-kh
        \\de-cg
        \\ka-co
        \\yn-aq
        \\qp-ub
        \\cg-tb
        \\vc-aq
        \\tb-ka
        \\wh-tc
        \\yn-cg
        \\kh-ub
        \\ta-co
        \\de-co
        \\tc-td
        \\tb-wqa
        \\wh-td
        \\ta-ka
        \\td-qp
        \\aq-cg
        \\wq-ub
        \\ub-vc
        \\de-ta
        \\wq-aq
        \\wq-vc
        \\wh-yn
        \\ka-de
        \\kh-ta
        \\co-tc
        \\wh-qp
        \\tb-vc
        \\td-yn
    ;
    const debugalloc = testing.allocator;
    var arena = std.heap.ArenaAllocator.init(debugalloc);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lan_map: std.StringHashMapUnmanaged(std.ArrayListUnmanaged([]const u8)) = .empty;

    var iterator = std.mem.splitScalar(u8, samples, '\n');
    while (iterator.next()) |row| {
        if (row.len == 0) break;
        try parsePairs(allocator, row, &lan_map);
    }

    const trios = try findTrios(allocator, &lan_map);

    for (trios.items) |trio| {
        print("{s}\n", .{trio});
    }

    try testing.expect(trios.items.len == 12);

    var start_with_t: u8 = 0;
    for (trios.items) |trio| {
        for (trio) |pc| {
            if (pc[0] == 't') {
                start_with_t += 1;
                break;
            }
        }
    }
    try testing.expect(start_with_t == 7);

    const current: std.ArrayListUnmanaged([]const u8) = .empty;
    const checked: std.ArrayListUnmanaged([]const u8) = .empty;
    var possible: std.ArrayListUnmanaged([]const u8) = .empty;
    var key_iter = lan_map.keyIterator();
    while (key_iter.next()) |key| {
        try possible.append(allocator, key.*);
    }
    var cliques: std.ArrayListUnmanaged(std.ArrayListUnmanaged([]const u8)) = .empty;

    try bronKerbosch(allocator, &lan_map, current, possible, checked, &cliques);
    print("\nPart 2\n", .{});

    var res2: usize = 0;
    var index2: usize = 0;
    for (cliques.items, 0..) |clique, i| {
        if (clique.items.len > res2) {
            res2 = clique.items.len;
            index2 = i;
        }
    }
    try testing.expect(res2 == 4);
    const biggest = cliques.items[index2].items;
    std.mem.sort([]const u8, biggest, {}, sortStrings);
    print("Biggest: {s}\n", .{biggest});
    const result = [4][]const u8{ "co", "de", "ka", "ta" };
    for (biggest, result) |a, b| {
        try testing.expect(compareStrings(a, b));
    }
}
