const std = @import("std");
const time = std.time;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

// Fibonacci utility functions
fn fibRec(n: usize) usize {
    if (n < 2) return n;
    return fibRec(n - 1) + fibRec(n - 2);
}

fn fibRecMemo(n: usize, cache: *AutoHashMap(usize, usize)) !usize {
    if (n < 2) return n;
    
    if (cache.get(n)) |val| {
        return val;
    }
    
    const val1 = try fibRecMemo(n - 1, cache);
    const val2 = try fibRecMemo(n - 2, cache);
    const result = val1 + val2;
    try cache.put(n, result);
    return result;
}

fn fibLoop(n: usize) usize {
    if (n < 2) return n;
    
    var a: usize = 0;
    var b: usize = 1;
    var i: usize = 2;
    while (i <= n) : (i += 1) {
        const tmp = a + b;
        a = b;
        b = tmp;
    }
    return b;
}

fn fibLoopMemory(n: usize, allocator: std.mem.Allocator) !usize {
    if (n < 2) return n;
    
    var arr = try ArrayList(usize).initCapacity(allocator, n + 1);
    defer arr.deinit();
    
    try arr.append(0);
    try arr.append(1);
    
    var i: usize = 2;
    while (i <= n) : (i += 1) {
        try arr.append(arr.items[i-1] + arr.items[i-2]);
    }
    return arr.items[n];
}

// Benchmark function
fn benchmark(comptime func: anytype, args: anytype, name: []const u8, iterations: usize) !void {
    var timer = try time.Timer.start();
    var i: usize = 0;
    var result: usize = undefined;
    
    // Warmup
    while (i < 1000) : (i += 1) {
        result = @call(.auto, func, args);
    }
    
    // Actual benchmark
    timer.reset();
    i = 0;
    while (i < iterations) : (i += 1) {
        result = @call(.auto, func, args);
    }
    
    const elapsed = timer.lap();
    const avg_ns = @as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(iterations));
    print("{s}: {d:.2} ns/iter (result: {d})\n", .{ name, avg_ns, result });
}

pub fn main() !void {
    const n: usize = 20;
    const iterations: usize = 1000;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    print("\nRunning Fibonacci Benchmarks (n={d}, iterations={d}):\n", .{ n, iterations });
    print("------------------------------------------------\n", .{});
    
    // Benchmark recursive version
    try benchmark(fibRec, .{n}, "Fib Rec", iterations);
    
    // Benchmark memoized recursive version
    {
        var cache = AutoHashMap(usize, usize).init(allocator);
        defer cache.deinit();
        const memo_result = try fibRecMemo(n, &cache);
        print("Fib Rec Memo: result = {d}\n", .{memo_result});
    }
    
    // Benchmark loop version
    try benchmark(fibLoop, .{n}, "Fib Loop", iterations);
    
    // Benchmark array version
    const array_result = try fibLoopMemory(n, allocator);
    print("Fib Loop Memory: result = {d}\n", .{array_result});
}

test "fibonacci functions give correct results" {
    const n: usize = 10;
    const expected: usize = 55;
    
    try std.testing.expectEqual(expected, fibRec(n));
    try std.testing.expectEqual(expected, fibLoop(n));
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var cache = AutoHashMap(usize, usize).init(allocator);
    defer cache.deinit();
    try std.testing.expectEqual(expected, try fibRecMemo(n, &cache));
    
    try std.testing.expectEqual(expected, try fibLoopMemory(n, allocator));
} 