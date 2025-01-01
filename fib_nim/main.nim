import std/[tables, monotimes, times, stats, strutils]

type USize = uint

# A small "black hole" mechanism to store results so
# the compiler doesn't trivially optimize them away.
var sink {.volatile.} : USize

proc blackHole(x: USize) {.noinline.} =
  sink = x

# ---------------------------------------------------
# Fibonacci implementations
# ---------------------------------------------------

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
  for _ in 2'u .. n:
    let tmp = a + b
    a = b
    b = tmp
  return b

proc fibLoopMemory(n: USize): USize =
  if n < 2:
    return n

  var arr = newSeq[USize](n.int + 1)
  arr[1] = 1
  for i in 2 .. n.int:
    arr[i] = arr[i - 1] + arr[i - 2]
  return arr[n.int]

# ---------------------------------------------------
# Benchmarking template
# ---------------------------------------------------
template timeItNano(name: string, iterations: int, body: untyped) =
  var samples: seq[float64] = @[]
  var localRes: USize

  echo "\nBenchmarking ", name, " (", iterations, " iterations)"
  for _ in 1 .. iterations:
    let start = getMonoTime()
    body
    let duration = getMonoTime() - start
    samples.add float64(duration.inNanoseconds)
    # Push the result into a "black hole" so it won't be optimized away:
    blackHole(localRes)

  echo "\n", name, " Results:"
  echo "  Mean:     ", formatFloat(mean(samples), format = ffDecimal, precision = 2), " ns"
  echo "  Std Dev:  ", formatFloat(standardDeviation(samples), format = ffDecimal, precision = 2), " ns"
  echo "  Min:      ", formatFloat(min(samples), format = ffDecimal, precision = 2), " ns"
  echo "  Max:      ", formatFloat(max(samples), format = ffDecimal, precision = 2), " ns"
  echo "  Result:   ", sink  # last stored value

# ---------------------------------------------------
# Main
# ---------------------------------------------------
when isMainModule:
  const n: USize = 20
  var cache = initTable[USize, USize]()
  
  # Recursive
  timeItNano("Recursive", 10_000):
    let localRes = fibRec(n)

  # Recursive + Memoization
  timeItNano("Recursive with Memoization", 3_000):
    cache.clear()
    let localRes = fibRecMemo(n, cache)

  # Iterative
  timeItNano("Iterative", 5_000_000):
    let localRes = fibLoop(n)

  # Iterative with Array
  timeItNano("Iterative with Array", 100_000):
    let localRes = fibLoopMemory(n)

  # Finally, just to confirm we used the value
  echo "Final sink value: ", sink
