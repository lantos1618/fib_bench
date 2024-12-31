package main

import (
	"testing"
)

// FibRec computes Fibonacci numbers recursively
func FibRec(n uint64) uint64 {
	if n < 2 {
		return n
	}
	return FibRec(n-1) + FibRec(n-2)
}

// FibRecMemo computes Fibonacci numbers recursively with memoization
func FibRecMemo(n uint64, cache map[uint64]uint64) uint64 {
	if n < 2 {
		return n
	}
	if val, exists := cache[n]; exists {
		return val
	}
	result := FibRecMemo(n-1, cache) + FibRecMemo(n-2, cache)
	cache[n] = result
	return result
}

// FibLoop computes Fibonacci numbers iteratively
func FibLoop(n uint64) uint64 {
	if n < 2 {
		return n
	}
	a, b := uint64(0), uint64(1)
	for i := uint64(2); i <= n; i++ {
		a, b = b, a+b
	}
	return b
}

// FibLoopMemory computes Fibonacci numbers iteratively using a slice
func FibLoopMemory(n uint64) uint64 {
	if n < 2 {
		return n
	}
	arr := make([]uint64, n+1)
	arr[1] = 1
	for i := uint64(2); i <= n; i++ {
		arr[i] = arr[i-1] + arr[i-2]
	}
	return arr[n]
}

func BenchmarkFibRec(b *testing.B) {
	n := uint64(20)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		FibRec(n)
	}
}

func BenchmarkFibRecMemo(b *testing.B) {
	n := uint64(20)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		cache := make(map[uint64]uint64)
		FibRecMemo(n, cache)
	}
}

func BenchmarkFibLoop(b *testing.B) {
	n := uint64(20)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		FibLoop(n)
	}
}

func BenchmarkFibLoopMemory(b *testing.B) {
	n := uint64(20)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		FibLoopMemory(n)
	}
}

func main() {
	// The main function is empty because the benchmarks are run using 'go test -bench .'
}
