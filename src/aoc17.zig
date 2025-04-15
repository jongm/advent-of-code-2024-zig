const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

const raw = @embedFile("inputs/input17.txt");

pub fn findNext(allocator: std.mem.Allocator, pos: usize, inst: []u8, matched: []u8, results: *std.ArrayListUnmanaged(u64)) !void {
    var current_a: u64 = 0;
    const len: usize = inst.len - 1;
    var a_buffer = try allocator.alloc(u8, inst.len);
    defer allocator.free(a_buffer);

    for (0..pos + 1) |pow| {
        current_a += matched[pow] * std.math.pow(u64, 8, pos - pow);
        //print("POWERING: POS {d}, POW {d}, MATCHED {any}, CALC {d}\n", .{ pos, pow, matched, current_a });
    }
    for (0..8) |n| {
        const check_a = current_a + n;
        var registers = [3]u64{ check_a, 0, 0 };
        var result_buffer: [20]u8 = undefined;
        var b_len: usize = 0;
        for (matched, 0..) |val, i| {
            a_buffer[i] = val;
        }
        runProgram(inst, &registers, &result_buffer, &b_len);
        // print("Checking: CURRENT: {d} CHECKA: {d} BUFFER: {any} INST: {any}\n", .{ current_a, check_a, result_buffer[0 .. pos + 1], inst[len - pos ..] });
        if (std.mem.eql(u8, result_buffer[0 .. pos + 1], inst[len - pos ..])) {
            //            print("POS {d}, CURRENTA {d}, CHECKA {d}, BUFFER {any}\n", .{ pos, current_a, check_a, result_buffer[0 .. pos + 1] });
            if (pos == len) {
                // print("REACHED {d} WITH A {d} BUFFER {any}\n", .{ len, check_a, result_buffer[len - pos ..] });
                try results.append(allocator, check_a);
                return;
            }
            const new_a: u8 = @intCast(n);
            a_buffer[pos] = new_a;
            _ = try findNext(allocator, pos + 1, inst, a_buffer, results);
        }
    }
}

pub fn getComboOperand(registers: *[3]u64, num: u8) u64 {
    const combo: u64 = switch (num) {
        0...3 => |x| @intCast(x),
        4 => registers[0],
        5 => registers[1],
        6 => registers[2],
        else => unreachable,
    };
    return combo;
}

pub fn op0Adv(registers: *[3]u64, pointer: *u8, op: u8) void {
    const combo = getComboOperand(registers, op);
    const numer: u64 = registers[0];
    const denom: u64 = std.math.pow(u64, 2, combo);
    const result: u64 = numer / denom;
    registers.*[0] = result;
    pointer.* += 2;
}

pub fn op1Bxl(registers: *[3]u64, pointer: *u8, op: u8) void {
    const result: u64 = registers[1] ^ op;
    registers.*[1] = result;
    pointer.* += 2;
}

pub fn op2Bst(registers: *[3]u64, pointer: *u8, op: u8) void {
    const combo = getComboOperand(registers, op);
    const result: u64 = combo % 8;
    registers.*[1] = result;
    pointer.* += 2;
}

pub fn op3Jnz(registers: *[3]u64, pointer: *u8, op: u8) void {
    if (registers[0] == 0) {
        pointer.* += 2;
    } else {
        pointer.* = op;
    }
}

pub fn op4Bxc(registers: *[3]u64, pointer: *u8, op: u8) void {
    _ = op;
    const result: u64 = registers[1] ^ registers[2];
    registers.*[1] = result;
    pointer.* += 2;
}

pub fn op5Out(registers: *[3]u64, pointer: *u8, op: u8, buffer: []u8, len: *usize) void {
    const combo = getComboOperand(registers, op);
    const result: u8 = @intCast(combo % 8);
    pointer.* += 2;
    buffer[len.*] = result;
    len.* += 1;
}

pub fn op6Bdv(registers: *[3]u64, pointer: *u8, op: u8) void {
    const combo = getComboOperand(registers, op);
    const numer: u64 = registers[0];
    const denom: u64 = std.math.pow(u64, 2, combo);
    const result: u64 = numer / denom;
    registers.*[1] = result;
    pointer.* += 2;
}

pub fn op7Cdv(registers: *[3]u64, pointer: *u8, op: u8) void {
    const combo = getComboOperand(registers, op);
    const numer: u64 = registers[0];
    const denom: u64 = std.math.pow(u64, 2, combo);
    const result: u64 = numer / denom;
    registers.*[2] = result;
    pointer.* += 2;
}

pub fn parseProgram(allocator: std.mem.Allocator, program: []const u8) ![]u8 {
    var iterator = std.mem.splitScalar(u8, program, ',');
    var len: u8 = 0;
    while (iterator.next()) |_| len += 1;
    var buffer = try allocator.alloc(u8, len);
    iterator.reset();
    var i: u8 = 0;
    while (iterator.next()) |num| : (i += 1) {
        const nump = try std.fmt.parseInt(u8, num, 10);
        buffer[i] = nump;
    }
    return buffer;
}

pub fn runProgram(instructions: []u8, registers: *[3]u64, buffer: []u8, len: *usize) void {
    var pointer: u8 = 0;
    while (true) {
        if (pointer >= instructions.len) break;
        if (len.* == buffer.len) break;

        const inst: u8 = instructions[pointer];
        const op: u8 = instructions[pointer + 1];
        switch (inst) {
            0 => op0Adv(registers, &pointer, op),
            1 => op1Bxl(registers, &pointer, op),
            2 => op2Bst(registers, &pointer, op),
            3 => op3Jnz(registers, &pointer, op),
            4 => op4Bxc(registers, &pointer, op),
            5 => op5Out(registers, &pointer, op, buffer, len),
            6 => op6Bdv(registers, &pointer, op),
            7 => op7Cdv(registers, &pointer, op),
            else => unreachable,
        }
    }
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const allocator = debug_allocator.allocator();

    var buffer: [16]u8 = undefined;
    var b_len: usize = 0;

    var registers = [3]u64{ 0, 0, 0 };

    var iterator = std.mem.splitSequence(u8, raw, "\n");

    for ([3][]const u8{ "A: ", "B: ", "C: " }, 0..) |letter, i| {
        const row = iterator.next().?;
        var letter_iter = std.mem.splitSequence(u8, row, letter);
        _ = letter_iter.next().?;
        registers[i] = try std.fmt.parseInt(u64, letter_iter.next().?, 10);
    }
    _ = iterator.next().?;
    const row_program = iterator.next().?;
    const start_index = std.mem.indexOf(u8, row_program, ":").?;
    const program = std.mem.trim(u8, row_program[start_index + 1 ..], " \n");

    // print("REGISTERS: {any}\n", .{registers});
    // print("PROGRAM: {any}\n", .{program});

    const instructions = try parseProgram(allocator, program);
    print("Instructions: {any} \n", .{instructions});
    defer allocator.free(instructions);
    // registers[0] = 236539226447469;
    runProgram(instructions, &registers, &buffer, &b_len);
    print("Result: {any} \n", .{buffer[0..b_len]});

    // Part 2
    const matched = try allocator.alloc(u8, instructions.len);
    for (matched, 0..) |_, i| {
        matched[i] = 0;
    }
    defer allocator.free(matched);
    var results_list: std.ArrayListUnmanaged(u64) = .empty;
    defer results_list.deinit(allocator);
    try findNext(allocator, 0, instructions, matched, &results_list);

    var res2: u64 = results_list.items[0];
    for (results_list.items) |item| {
        if (item < res2) res2 = item;
    }
    print("Result 2: {d}", .{res2});
}

test "sample" {
    var allocator = testing.allocator;

    var registers = [3]u64{ 729, 0, 0 };
    const program = "0,1,5,4,3,0";
    const result = [_]u8{ 4, 6, 3, 5, 6, 3, 5, 2, 1, 0 };
    var buffer: [20]u8 = undefined;
    var b_len: usize = 0;

    const instructions = try parseProgram(allocator, program);
    defer allocator.free(instructions);

    runProgram(instructions, &registers, &buffer, &b_len);

    print("Sample Output: {any}\n", .{buffer[0..b_len]});
    try testing.expect(std.mem.eql(u8, buffer[0..b_len], &result));
}

test "sample2" {
    var allocator = testing.allocator;

    var registers = [3]u64{ 117440, 0, 0 };
    const program = "0,3,5,4,3,0";
    const result = [_]u8{ 0, 3, 5, 4, 3, 0 };

    var buffer: [20]u8 = undefined;
    var b_len: usize = 0;

    const instructions = try parseProgram(allocator, program);
    defer allocator.free(instructions);

    runProgram(instructions, &registers, &buffer, &b_len);

    print("Sample Output 2: {any}\n", .{buffer[0..b_len]});
    try testing.expect(std.mem.eql(u8, buffer[0..b_len], &result));
}
