from timeit import timeit
from typing import Dict, List
from functools import lru_cache

##################
# Fibonacci Utils
##################

class FibUtil:
    @staticmethod
    def fib_rec(n: int) -> int:
        if n < 2:
            return n
        return FibUtil.fib_rec(n - 1) + FibUtil.fib_rec(n - 2)
    
    @staticmethod
    def fib_rec_memo(n: int, cache: Dict[int, int] = None) -> int:
        if cache is None:
            cache = {}
        if n < 2:
            return n
        if n in cache:
            return cache[n]
        
        val1 = FibUtil.fib_rec_memo(n - 1, cache)
        val2 = FibUtil.fib_rec_memo(n - 2, cache)
        result = val1 + val2
        cache[n] = result
        return result

    @staticmethod
    def fib_loop(n: int) -> int:
        if n < 2:
            return n
        
        a, b = 0, 1
        for _ in range(2, n + 1):
            tmp = a + b
            a = b
            b = tmp
        return b

    @staticmethod
    def fib_loop_memory(n: int) -> int:
        if n < 2:
            return n
        
        arr = [0] * (n + 1)
        arr[1] = 1
        for i in range(2, n + 1):
            arr[i] = arr[i-1] + arr[i-2]
        return arr[n]

##################
# Benchmarks
##################

def run_benchmarks(n: int = 20):
    benchmarks = [
        ("Fib Rec", lambda: FibUtil.fib_rec(n), 10000),
        ("Fib Rec Memo", lambda: FibUtil.fib_rec_memo(n), 3000),
        ("Fib Loop", lambda: FibUtil.fib_loop(n), 5000000),
        ("Fib Loop Memory", lambda: FibUtil.fib_loop_memory(n), 100000)
    ]

    results = []
    for name, func, iterations in benchmarks:
        time = timeit(func, number=iterations)
        avg_time = time / iterations * 1e9  # Convert to nanoseconds
        results.append((name, avg_time))

    # Print results
    print("\nRunning Fibonacci benchmarks (n=20)...\n")
    for name, avg_time in results:
        print(f"{name:<30} {avg_time:>6.0f} ns (min: {avg_time:>9.0f} ns) [iterations: {iterations}]")

if __name__ == "__main__":
    run_benchmarks()
