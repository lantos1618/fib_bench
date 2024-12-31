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

// Benchmark statistics
const BenchStats = struct {
    mean: f64,
    median: f64,
    min: f64,
    max: f64,
    std_dev: f64,
};

fn calcStats(samples: []f64) BenchStats {
    var sum: f64 = 0;
    var min: f64 = samples[0];
    var max: f64 = samples[0];
    
    // First pass: mean, min, max
    for (samples) |sample| {
        sum += sample;
        min = @min(min, sample);
        max = @max(max, sample);
    }
    const mean = sum / @as(f64, @floatFromInt(samples.len));
    
    // Second pass: standard deviation
    var variance_sum: f64 = 0;
    for (samples) |sample| {
        const diff = sample - mean;
        variance_sum += diff * diff;
    }
    const std_dev = @sqrt(variance_sum / @as(f64, @floatFromInt(samples.len)));
    
    // Calculate median
    std.sort.heap(f64, samples, {}, std.sort.asc(f64));
    const median = if (samples.len % 2 == 0)
        (samples[samples.len/2 - 1] + samples[samples.len/2]) / 2.0
    else
        samples[samples.len/2];
    
    return .{
        .mean = mean,
        .median = median,
        .min = min,
        .max = max,
        .std_dev = std_dev,
    };
}

// Enhanced benchmark function
fn benchmark(comptime func: anytype, args: anytype, name: []const u8, iterations: usize, warmup_iters: usize) !void {
    var timer = try time.Timer.start();
    var samples = std.ArrayList(f64).init(std.heap.page_allocator);
    defer samples.deinit();
    
    var result: usize = undefined;
    
    // Warmup phase
    print("\nWarming up {s} for {d} iterations...\n", .{ name, warmup_iters });
    var i: usize = 0;
    while (i < warmup_iters) : (i += 1) {
        const call_result = @call(.auto, func, args);
        result = if (@TypeOf(call_result) == usize) call_result else try call_result;
        std.mem.doNotOptimizeAway(result);
    }
    
    // Measurement phase
    print("Running {s} for {d} iterations...\n", .{ name, iterations });
    i = 0;
    while (i < iterations) : (i += 1) {
        timer.reset();
        const call_result = @call(.auto, func, args);
        result = if (@TypeOf(call_result) == usize) call_result else try call_result;
        std.mem.doNotOptimizeAway(result);
        const elapsed_ns = timer.lap();
        try samples.append(@as(f64, @floatFromInt(elapsed_ns)));
    }
    
    const stats = calcStats(samples.items);
    
    print("\n{s} Results:\n", .{name});
    print("  Mean:     {d:.2} ns\n", .{stats.mean});
    print("  Median:   {d:.2} ns\n", .{stats.median});
    print("  Min:      {d:.2} ns\n", .{stats.min});
    print("  Max:      {d:.2} ns\n", .{stats.max});
    print("  Std Dev:  {d:.2} ns\n", .{stats.std_dev});
    print("  Result:   {d}\n", .{result});
}

pub fn main() !void {
    const n: usize = 20;
    const iterations: usize = 10000;
    const warmup_iters: usize = 1000;
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    print("\nFibonacci Benchmarks (n={d})\n", .{n});
    print("=========================\n", .{});
    
    // Benchmark recursive version
    try benchmark(fibRec, .{n}, "Fibonacci Recursive", iterations, warmup_iters);
    
    // Benchmark memoized recursive version
    const BenchMemoContext = struct {
        allocator: std.mem.Allocator,
        n: usize,
        
        fn wrapped(self: @This()) !usize {
            var cache = AutoHashMap(usize, usize).init(self.allocator);
            defer cache.deinit();
            return fibRecMemo(self.n, &cache);
        }
    };
    
    try benchmark(
        BenchMemoContext.wrapped,
        .{.{ .allocator = allocator, .n = n }},
        "Fibonacci Recursive Memoized",
        iterations,
        warmup_iters,
    );
    
    // Benchmark loop version
    try benchmark(fibLoop, .{n}, "Fibonacci Loop", iterations, warmup_iters);
    
    // Benchmark array version
    const BenchArrayContext = struct {
        allocator: std.mem.Allocator,
        n: usize,
        
        fn wrapped(self: @This()) !usize {
            return fibLoopMemory(self.n, self.allocator);
        }
    };
    
    try benchmark(
        BenchArrayContext.wrapped,
        .{.{ .allocator = allocator, .n = n }},
        "Fibonacci Loop with Memory",
        iterations,
        warmup_iters,
    );
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