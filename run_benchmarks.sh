#!/bin/bash

CWD=$(pwd)

echo "Running Fibonacci Benchmarks across different languages..."
echo "======================================================="

# Rust benchmark
echo "\nRunning Rust benchmark..."
cd $CWD/fib_rust && cargo bench && cd ..

# Zig benchmark
echo "\nRunning Zig benchmark..."
cd $CWD/fib_zig && zig build run && cd ..

# Nim benchmark
echo "\nRunning Nim benchmark..."
cd $CWD/fib_nim && nim c -r -d:release main.nim && cd ..

# C benchmark
echo "\nRunning C benchmark..."
cd $CWD/fib_c && make clean && make && make run && cd ..

# Python benchmark
echo "\nRunning Python benchmark..."
cd $CWD/fib_python && python3 main.py && cd ..

# Pony benchmark
echo "\nRunning Pony benchmark..."
cd $CWD/fib_pony && ponyc && ./fib_pony && cd ..

# Gleam benchmark
echo "\nRunning Gleam benchmark..."
cd $CWD/fib_gleam && gleam run && cd ..
