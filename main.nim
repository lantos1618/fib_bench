import std/[tables, times, strformat]

# Fibonacci utility functions
proc fibRec(n: int): int =
  if n < 2:
    return n
  return fibRec(n - 1) + fibRec(n - 2)

proc fibRecMemo(n: int, cache: var Table[int, int]): int =
  if n < 2:
    return n
  
  if cache.hasKey(n):
    return cache[n]
  
  let val1 = fibRecMemo(n - 1, cache)
  let val2 = fibRecMemo(n - 2, cache)
  let result = val1 + val2
  cache[n] = result
  return result

proc fibLoop(n: int): int =
  if n < 2:
    return n
  
  var a = 0
  var b = 1
  for _ in 2..n:
    let tmp = a + b
    a = b
    b = tmp
  return b

proc fibLoopMemory(n: int): int =
  if n < 2:
    return n
  
  var arr = newSeq[int](n + 1)
  arr[1] = 1
  for i in 2..n:
    arr[i] = arr[i-1] + arr[i-2]
  return arr[n]

# Benchmark helper
proc benchmark(name: string, iterations: int, fn: proc()) =
  let start = cpuTime()
  for _ in 1..iterations:
    fn()
  let duration = cpuTime() - start
  let avgTime = duration / float(iterations)
  echo fmt"{name}: {avgTime:.6f} seconds per iteration (total: {duration:.6f}s for {iterations} iterations)"

# Main benchmarking
when isMainModule:
  const n = 20
  const iterations = 1000

  var cache = initTable[int, int]()
  
  benchmark("Fib Rec (n=20)", iterations):
    discard fibRec(n)
  
  benchmark("Fib Rec Memo (n=20)", iterations):
    cache.clear()
    discard fibRecMemo(n, cache)
  
  benchmark("Fib Loop (n=20)", iterations):
    discard fibLoop(n)
  
  benchmark("Fib Loop Memory (n=20)", iterations):
    discard fibLoopMemory(n) 