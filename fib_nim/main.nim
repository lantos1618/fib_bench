import std/[tables, monotimes, times, stats, strformat, strutils]
import benchy

type USize = uint

# Fibonacci utility functions
proc fibRec(n: USize): USize =
  if n < 2:
    return n
  return fibRec(n - 1) + fibRec(n - 2)

proc fibRecMemo(n: USize, cache: var Table[USize, USize] = initTable[USize, USize]()): USize =
  if n < 2:
    return n
  
  if cache.hasKey(n):
    return cache[n]
  
  let val1 = fibRecMemo(n - 1, cache)
  let val2 = fibRecMemo(n - 2, cache)
  result = val1 + val2
  cache[n] = result
  return result

proc fibLoop(n: USize): USize =
  if n < 2:
    return n
  
  var a: USize = 0
  var b: USize = 1
  for _ in 2'u..n:
    let tmp = a + b
    a = b
    b = tmp
  return b

proc fibLoopMemory(n: USize): USize =
  if n < 2:
    return n
  
  var arr = newSeq[USize](n.int + 1)
  arr[1] = 1
  for i in 2..n.int:
    arr[i] = arr[i-1] + arr[i-2]
  return arr[n.int]

# Main benchmarking
when isMainModule:
  const n: USize = 20
  var cache = initTable[USize, USize]()
  var result: USize
  
  template timeItNano(name: string, iterations: int, body: untyped) =
    var samples: seq[float64] = @[]
    var res: USize
    echo "\nBenchmarking ", name, " (", iterations, " iterations)"
    for i in 1..iterations:
      let start = getMonoTime()
      body
      let duration = getMonoTime() - start
      samples.add float64(duration.inNanoseconds)
      res = result # Prevent optimization
    
    echo "\n", name, " Results:"
    echo "  Mean:     ", formatFloat(mean(samples), format = ffDecimal, precision = 2), " ns"
    echo "  Std Dev:  ", formatFloat(standardDeviation(samples), format = ffDecimal, precision = 2), " ns"
    echo "  Min:      ", formatFloat(min(samples), format = ffDecimal, precision = 2), " ns"
    echo "  Max:      ", formatFloat(max(samples), format = ffDecimal, precision = 2), " ns"
    echo "  Result:   ", res
  
  # Match Pony's iteration counts for each benchmark
  timeItNano "Recursive", 10_000:
    result = fibRec(n)
  
  timeItNano "Recursive with Memoization", 3_000:
    cache.clear()
    result = fibRecMemo(n, cache)
  
  timeItNano "Iterative", 5_000_000:
    result = fibLoop(n)
  
  timeItNano "Iterative with Array", 100_000:
    result = fibLoopMemory(n)
  
  # Print final result to prevent optimization
  echo "Final result: ", result 