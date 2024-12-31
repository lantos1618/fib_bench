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

def run_benchmarks(n: int = 20, number: int = 1000):
    benchmarks = [
        ("Fib Rec (n=20)", lambda: FibUtil.fib_rec(n)),
        ("Fib Rec Memo (n=20)", lambda: FibUtil.fib_rec_memo(n)),
        ("Fib Loop (n=20)", lambda: FibUtil.fib_loop(n)),
        ("Fib Loop Memory (n=20)", lambda: FibUtil.fib_loop_memory(n))
    ]

    results = []
    for name, func in benchmarks:
        time = timeit(func, number=number)
        avg_time = time / number * 1e9  # Convert to nanoseconds
        results.append((name, avg_time))

    # Print results
    print("\nBenchmark Results:")
    print("-" * 50)
    for name, avg_time in results:
        print(f"{name:<25} {avg_time:>10.2f} ns/iter")

if __name__ == "__main__":
    run_benchmarks()
