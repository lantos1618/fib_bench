#!/bin/bash

echo "Running Fibonacci Benchmarks across different languages..."
echo "======================================================="

# Rust benchmark
echo "\nRunning Rust benchmark..."
cd fib_rust && cargo bench && cd ..

# Zig benchmark
echo "\nRunning Zig benchmark..."
cd fib_zig && zig build run && cd ..

# Nim benchmark
echo "\nRunning Nim benchmark..."
cd fib_nim && nim c -r main.nim && cd ..

# C benchmark
echo "\nRunning C benchmark..."
cd fib_c && make clean && make && make run && cd ..

# Python benchmark
echo "\nRunning Python benchmark..."
cd fib_python && python3 main.py && cd ..

# Pony benchmark
echo "\nRunning Pony benchmark..."
cd fib_pony && ponyc && ./fib_bench && cd ..

# Gleam benchmark
echo "\nRunning Gleam benchmark..."
cd fib_gleam && gleam run && cd ..