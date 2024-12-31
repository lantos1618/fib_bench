#!/bin/bash

echo "Running Fibonacci Benchmarks across different languages..."
echo "======================================================="

# Rust benchmark
echo "\nRunning Rust benchmark..."
cargo bench

# Zig benchmark
echo "\nRunning Zig benchmark..."
zig build run

# Nim benchmark
echo "\nRunning Nim benchmark..."
nim c -r main.nim

# C benchmark
echo "\nRunning C benchmark..."
make clean && make && make run                                  

# Python benchmark
echo "\nRunning Python benchmark..."
python3 main.py

# Pony benchmark
echo "\nRunning Pony benchmark..."
ponyc && ./fib_bench