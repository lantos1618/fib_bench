#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>  // For PRIu64 format specifier

// Known correct value for fib(20)
#define FIB_20 6765
#define BATCH_SIZE 100  // Number of iterations to time together for more precision

// Force memory read/write - prevent optimization
static volatile uint64_t dummy_result = 0;

// Memory barrier to prevent reordering
static inline void memory_barrier(void) {
    asm volatile("" ::: "memory");
}

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
    
    volatile size_t a = 0, b = 1;  // Make variables volatile to prevent optimization
    for (size_t i = 2; i <= n; i++) {
        // Check for overflow
        if (a > SIZE_MAX - b) {
            fprintf(stderr, "Overflow detected in fib_loop!\n");
            exit(1);
        }
        size_t tmp = a + b;
        a = b;
        b = tmp;
        memory_barrier();  // Prevent loop optimization
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
    if (n == 20 && expected_result != FIB_20) {
        fprintf(stderr, "Error: Expected fib(20) = %d, but got %zu\n", FIB_20, expected_result);
        exit(1);
    }
    
    uint64_t total_time = 0;
    uint64_t min_time = UINT64_MAX;
    
    // Create array of slightly varied inputs around n
    size_t* inputs = (size_t*)malloc(BATCH_SIZE * sizeof(size_t));
    size_t* expected_outputs = (size_t*)malloc(BATCH_SIZE * sizeof(size_t));
    if (!inputs || !expected_outputs) {
        fprintf(stderr, "Memory allocation failed!\n");
        exit(1);
    }
    
    // Generate input variations and precompute expected outputs
    for (size_t i = 0; i < BATCH_SIZE; i++) {
        // Vary between n-1, n, and n+1 to prevent pure caching
        inputs[i] = n + (i % 3) - 1;
        expected_outputs[i] = func(inputs[i]);  // Precompute expected results
    }
    
    // Warmup with varied inputs
    for (size_t i = 0; i < 100; i++) {
        dummy_result = func(inputs[i % BATCH_SIZE]);
        memory_barrier();
    }
    
    // Actual benchmark
    for (size_t i = 0; i < iterations; i += BATCH_SIZE) {
        size_t batch = (i + BATCH_SIZE <= iterations) ? BATCH_SIZE : iterations - i;
        
        memory_barrier();
        uint64_t start = get_time_ns();
        
        for (size_t j = 0; j < batch; j++) {
            size_t idx = j % BATCH_SIZE;
            size_t result = func(inputs[idx]);
            if (result != expected_outputs[idx]) {
                printf("Error: Incorrect result for %s\n", name);
                free(inputs);
                free(expected_outputs);
                return;
            }
            dummy_result = result;  // Prevent optimization
            memory_barrier();
        }
        
        uint64_t end = get_time_ns();
        memory_barrier();
        
        uint64_t duration = (end - start) / batch;  // Average time per iteration
        total_time += duration * batch;
        if (duration < min_time) min_time = duration;
    }
    
    free(inputs);
    free(expected_outputs);
    
    double mean_ns = (double)total_time / iterations;
    printf("%-30s %8.0f ns (min: %8" PRIu64 " ns) [iterations: %zu]\n", 
           name, mean_ns, min_time, iterations);
}

// Special benchmark functions for memoized version
void benchmark_memo(const char* name, size_t iterations, size_t n) {
    uint64_t total_time = 0;
    uint64_t min_time = UINT64_MAX;
    
    // Create array of slightly varied inputs around n
    size_t* inputs = (size_t*)malloc(BATCH_SIZE * sizeof(size_t));
    size_t* expected_outputs = (size_t*)malloc(BATCH_SIZE * sizeof(size_t));
    if (!inputs || !expected_outputs) {
        fprintf(stderr, "Memory allocation failed!\n");
        exit(1);
    }
    
    // Generate input variations and precompute expected outputs
    for (size_t i = 0; i < BATCH_SIZE; i++) {
        inputs[i] = n + (i % 3) - 1;  // Vary between n-1, n, and n+1
        expected_outputs[i] = fib_loop(inputs[i]);  // Use loop version as reference
    }
    
    // Validate fib(20) if it's in our input range
    for (size_t i = 0; i < BATCH_SIZE; i++) {
        if (inputs[i] == 20 && expected_outputs[i] != FIB_20) {
            fprintf(stderr, "Error: Expected fib(20) = %d, but got %zu\n", FIB_20, expected_outputs[i]);
            free(inputs);
            free(expected_outputs);
            exit(1);
        }
    }
    
    // Warmup
    size_t* cache = (size_t*)calloc(n + 2, sizeof(size_t));  // +2 to handle n+1 inputs
    if (!cache) {
        fprintf(stderr, "Memory allocation failed!\n");
        free(inputs);
        free(expected_outputs);
        exit(1);
    }
    
    for (size_t i = 0; i < 100; i++) {
        memset(cache, 0, (n + 2) * sizeof(size_t));
        dummy_result = fib_rec_memo(inputs[i % BATCH_SIZE], cache, n + 2);
        memory_barrier();
    }
    
    // Actual benchmark
    for (size_t i = 0; i < iterations; i += BATCH_SIZE) {
        size_t batch = (i + BATCH_SIZE <= iterations) ? BATCH_SIZE : iterations - i;
        
        memory_barrier();
        uint64_t start = get_time_ns();
        
        for (size_t j = 0; j < batch; j++) {
            size_t idx = j % BATCH_SIZE;
            memset(cache, 0, (n + 2) * sizeof(size_t));
            size_t result = fib_rec_memo(inputs[idx], cache, n + 2);
            if (result != expected_outputs[idx]) {
                printf("Error: Incorrect result for %s\n", name);
                free(inputs);
                free(expected_outputs);
                free(cache);
                return;
            }
            dummy_result = result;  // Prevent optimization
            memory_barrier();
        }
        
        uint64_t end = get_time_ns();
        memory_barrier();
        
        uint64_t duration = (end - start) / batch;  // Average time per iteration
        total_time += duration * batch;
        if (duration < min_time) min_time = duration;
    }
    
    free(inputs);
    free(expected_outputs);
    free(cache);
    
    double mean_ns = (double)total_time / iterations;
    printf("%-30s %8.0f ns (min: %8" PRIu64 " ns) [iterations: %zu]\n", 
           name, mean_ns, min_time, iterations);
}

int main() {
    const size_t N = 20;  // Same as Pony benchmark
    
    // Validate all implementations give correct result for fib(20)
    if (fib_loop(20) != FIB_20) {
        fprintf(stderr, "fib_loop(20) gives wrong result!\n");
        return 1;
    }
    if (fib_loop_memory(20) != FIB_20) {
        fprintf(stderr, "fib_loop_memory(20) gives wrong result!\n");
        return 1;
    }
    if (fib_rec(20) != FIB_20) {
        fprintf(stderr, "fib_rec(20) gives wrong result!\n");
        return 1;
    }
    
    size_t cache[21] = {0};  // Size 21 to accommodate n=20
    if (fib_rec_memo(20, cache, 21) != FIB_20) {
        fprintf(stderr, "fib_rec_memo(20) gives wrong result!\n");
        return 1;
    }
    
    printf("\nRunning Fibonacci benchmarks (n=%zu)...\n\n", N);
    
    // Run benchmarks with different iteration counts based on expected performance
    benchmark("Fib Rec", 10000, N, fib_rec, fib_loop(N));
    benchmark_memo("Fib Rec Memo", 1000000, N);
    benchmark("Fib Loop", 10000000, N, fib_loop, fib_loop(N));
    benchmark("Fib Loop Memory", 1000000, N, fib_loop_memory, fib_loop(N));
    
    return 0;
} 