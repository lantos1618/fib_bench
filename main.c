#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>  // For PRIu64 format specifier

// Utility function to get high precision time in nanoseconds
static inline uint64_t get_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
}

// Fibonacci implementations
size_t fib_rec(size_t n) {
    if (n < 2) return n;
    size_t a = fib_rec(n - 1);
    size_t b = fib_rec(n - 2);
    // Check for overflow
    if (a > SIZE_MAX - b) {
        fprintf(stderr, "Overflow detected in fib_rec!\n");
        exit(1);
    }
    return a + b;
}

size_t fib_rec_memo(size_t n, size_t* cache, size_t cache_size) {
    if (n >= cache_size) {
        fprintf(stderr, "Cache size too small!\n");
        exit(1);
    }
    if (n < 2) return n;
    if (cache[n] != 0) return cache[n];
    
    size_t a = fib_rec_memo(n - 1, cache, cache_size);
    size_t b = fib_rec_memo(n - 2, cache, cache_size);
    
    // Check for overflow
    if (a > SIZE_MAX - b) {
        fprintf(stderr, "Overflow detected in fib_rec_memo!\n");
        exit(1);
    }
    
    cache[n] = a + b;
    return cache[n];
}

size_t fib_loop(size_t n) {
    if (n < 2) return n;
    
    size_t a = 0, b = 1;
    for (size_t i = 2; i <= n; i++) {
        // Check for overflow
        if (a > SIZE_MAX - b) {
            fprintf(stderr, "Overflow detected in fib_loop!\n");
            exit(1);
        }
        size_t tmp = a + b;
        a = b;
        b = tmp;
    }
    return b;
}

size_t fib_loop_memory(size_t n) {
    if (n < 2) return n;
    
    size_t* arr = (size_t*)calloc(n + 1, sizeof(size_t));
    if (!arr) {
        fprintf(stderr, "Memory allocation failed!\n");
        exit(1);
    }
    
    arr[1] = 1;
    
    for (size_t i = 2; i <= n; i++) {
        // Check for overflow
        if (arr[i-1] > SIZE_MAX - arr[i-2]) {
            fprintf(stderr, "Overflow detected in fib_loop_memory!\n");
            free(arr);
            exit(1);
        }
        arr[i] = arr[i-1] + arr[i-2];
    }
    
    size_t result = arr[n];
    free(arr);
    return result;
}

// Benchmark function
void benchmark(const char* name, size_t iterations, size_t n,
              size_t (*func)(size_t), size_t expected_result) {
    uint64_t total_time = 0;
    uint64_t min_time = UINT64_MAX;
    
    // Warmup
    for (size_t i = 0; i < 100; i++) {
        func(n);
    }
    
    // Actual benchmark
    for (size_t i = 0; i < iterations; i++) {
        uint64_t start = get_time_ns();
        size_t result = func(n);
        uint64_t end = get_time_ns();
        
        if (result != expected_result) {
            printf("Error: Incorrect result for %s\n", name);
            return;
        }
        
        uint64_t duration = end - start;
        total_time += duration;
        if (duration < min_time) min_time = duration;
    }
    
    double mean_ns = (double)total_time / iterations;
    printf("%-30s %8.0f ns (min: %8" PRIu64 " ns) [iterations: %zu]\n", 
           name, mean_ns, min_time, iterations);
}

// Special benchmark functions for memoized version
void benchmark_memo(const char* name, size_t iterations, size_t n) {
    uint64_t total_time = 0;
    uint64_t min_time = UINT64_MAX;
    size_t expected = fib_loop(n);  // Use loop version as reference
    
    // Warmup
    size_t* cache = (size_t*)calloc(n + 1, sizeof(size_t));
    if (!cache) {
        fprintf(stderr, "Memory allocation failed!\n");
        exit(1);
    }
    
    for (size_t i = 0; i < 100; i++) {
        memset(cache, 0, (n + 1) * sizeof(size_t));
        fib_rec_memo(n, cache, n + 1);
    }
    
    // Actual benchmark
    for (size_t i = 0; i < iterations; i++) {
        memset(cache, 0, (n + 1) * sizeof(size_t));
        uint64_t start = get_time_ns();
        size_t result = fib_rec_memo(n, cache, n + 1);
        uint64_t end = get_time_ns();
        
        if (result != expected) {
            printf("Error: Incorrect result for %s\n", name);
            free(cache);
            return;
        }
        
        uint64_t duration = end - start;
        total_time += duration;
        if (duration < min_time) min_time = duration;
    }
    
    free(cache);
    double mean_ns = (double)total_time / iterations;
    printf("%-30s %8.0f ns (min: %8" PRIu64 " ns) [iterations: %zu]\n", 
           name, mean_ns, min_time, iterations);
}

int main() {
    const size_t N = 20;  // Same as Pony benchmark
    
    printf("\nRunning Fibonacci benchmarks (n=%zu)...\n\n", N);
    
    // Run benchmarks with different iteration counts based on expected performance
    benchmark("Fib Rec", 10000, N, fib_rec, fib_loop(N));
    benchmark_memo("Fib Rec Memo", 3000, N);
    benchmark("Fib Loop", 5000000, N, fib_loop, fib_loop(N));
    benchmark("Fib Loop Memory", 100000, N, fib_loop_memory, fib_loop(N));
    
    return 0;
} 