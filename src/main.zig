const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const time = std.time;

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
        try arr.append(arr.items[i - 1] + arr.items[i - 2]);
    }
    return arr.items[n];
}

fn calcMedian(samples: []const u64, allocator: std.mem.Allocator) !u64 {
    if (samples.len == 0) return 0;
    if (samples.len == 1) return samples[0];

    // Create a mutable copy of samples to sort
    var sorted = try ArrayList(u64).initCapacity(allocator, samples.len);
    defer sorted.deinit();
    try sorted.appendSlice(samples);

    std.sort.heap(u64, sorted.items, {}, std.sort.asc(u64));

    const mid = samples.len / 2;
    if (samples.len % 2 == 0) {
        return @divFloor(sorted.items[mid - 1] + sorted.items[mid], 2);
    } else {
        return sorted.items[mid];
    }
}

fn calcStdDev(samples: []const u64, mean: f64) f64 {
    if (samples.len <= 1) return 0;

    var sum_squared_diff: f64 = 0;
    for (samples) |sample| {
        const diff = @as(f64, @floatFromInt(sample)) - mean;
        sum_squared_diff += diff * diff;
    }

    return @sqrt(sum_squared_diff / @as(f64, @floatFromInt(samples.len - 1)));
}

fn benchmark(comptime func: anytype, args: anytype, name: []const u8, iterations: usize, allocator: std.mem.Allocator) !void {
    var timer = try time.Timer.start();
    var result: usize = undefined;

    // Warmup
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        result = switch (@typeInfo(@TypeOf(@call(.auto, func, args)))) {
            .ErrorUnion => try @call(.auto, func, args),
            else => @call(.auto, func, args),
        };
    }

    // Collect samples
    var samples = try ArrayList(u64).initCapacity(allocator, iterations);
    defer samples.deinit();

    i = 0;
    while (i < iterations) : (i += 1) {
        timer.reset();
        result = switch (@typeInfo(@TypeOf(@call(.auto, func, args)))) {
            .ErrorUnion => try @call(.auto, func, args),
            else => @call(.auto, func, args),
        };
        const elapsed = timer.lap();
        try samples.append(elapsed);
    }

    // Calculate statistics
    var total: u64 = 0;
    for (samples.items) |sample| {
        total += sample;
    }
    const mean = @as(f64, @floatFromInt(total)) / @as(f64, @floatFromInt(iterations));
    const median = try calcMedian(samples.items, allocator);
    const std_dev = calcStdDev(samples.items, mean);
    const deviation_percent = (std_dev / mean) * 100.0;

    print("{s:<30}{d:>15}ns{d:>12}ns  ± {d:>6.2}%{d:>12}\n", .{
        name,
        @as(u64, @intFromFloat(@round(mean))),
        median,
        deviation_percent,
        iterations,
    });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const n: usize = 20;

    print("\nBenchmark{s}mean{s}median{s}deviation{s}iterations\n", .{
        " " ** 21,
        " " ** 12,
        " " ** 12,
        " " ** 8,
    });
    print("{s}\n", .{"=" ** 80});

    // Benchmark recursive version
    try benchmark(fibRec, .{n}, "Fib Rec (n=20)", 10000, allocator);

    // Benchmark memoized recursive version
    {
        var cache = AutoHashMap(usize, usize).init(allocator);
        defer cache.deinit();
        const MemoFn = struct {
            cache: *AutoHashMap(usize, usize),
            fn call(self: *const @This(), num: usize) !usize {
                return fibRecMemo(num, self.cache);
            }
        };
        const memo = MemoFn{ .cache = &cache };
        try benchmark(MemoFn.call, .{ &memo, n }, "Fib Rec Memo (n=20)", 3000, allocator);
    }

    // Benchmark loop version
    try benchmark(fibLoop, .{n}, "Fib Loop (n=20)", 5000000, allocator);

    // Benchmark array version
    const ArrayFn = struct {
        allocator: std.mem.Allocator,
        fn call(self: *const @This(), num: usize) !usize {
            return fibLoopMemory(num, self.allocator);
        }
    };
    const array_fn = ArrayFn{ .allocator = allocator };
    try benchmark(ArrayFn.call, .{ &array_fn, n }, "Fib Loop Memory (n=20)", 100000, allocator);
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
