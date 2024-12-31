use "collections"
// Depending on your pony-bench setup, the import might look like:
use "pony_bench"


////////////////////////////////////////////////////////////////////////////////
// Fibonacci utility functions
////////////////////////////////////////////////////////////////////////////////

primitive FibUtil
  fun fib_rec(n: USize): USize =>
    if n < 2 then
      n
    else
      fib_rec(n - 1) + fib_rec(n - 2)
    end

  fun fib_rec_memo(n: USize, cache: Map[USize, USize] ref = Map[USize, USize]): USize =>
    if n < 2 then
      n
    else
      try
        cache(n)?
      else
        let val1 = fib_rec_memo(n - 1, cache)
        let val2 = fib_rec_memo(n - 2, cache)
        let result = val1 + val2
        cache(n) = result
        result
      end
    end



  fun fib_loop(n: USize): USize =>
    if n < 2 then
      n
    else
      var a: USize = 0
      var b: USize = 1
      for _ in Range[USize](2, n + 1) do
        let tmp = a + b
        a = b
        b = tmp
      end
      b
    end

  fun fib_loop_memory(n: USize): USize ? =>
    if n < 2 then
      n
    else
      var arr = Array[USize].init(n + 1, 0)
      arr(1)? = 1
      for i in Range[USize](2, n + 1) do
        arr(i)? = arr(i - 1)? + arr(i - 2)?
      end
      arr(n)?
    end

////////////////////////////////////////////////////////////////////////////////
// Benchmarks
////////////////////////////////////////////////////////////////////////////////

class iso FibRecBenchmark is MicroBenchmark
  let _n: USize = 20

  fun name(): String => "Fib Rec (n=20)"

  fun ref apply() =>
    // We measure one iteration by computing fib_rec(_n).
    // `DoNotOptimise[...]` is used to prevent the compiler from optimizing away.
    DoNotOptimise[USize](FibUtil.fib_rec(_n))
    DoNotOptimise.observe()

class iso FibRecMemoBenchmark is MicroBenchmark
  let _n: USize = 20

  fun name(): String => "Fib Rec Memo (n=20)"

  fun ref apply() =>
    DoNotOptimise[USize](FibUtil.fib_rec_memo(_n))
    DoNotOptimise.observe()

class iso FibLoopBenchmark is MicroBenchmark
  let _n: USize = 20

  fun name(): String => "Fib Loop (n=20)"

  fun ref apply() =>
    DoNotOptimise[USize](FibUtil.fib_loop(_n))
    DoNotOptimise.observe()

class iso FibLoopMemBenchmark is MicroBenchmark
  let _n: USize = 20

  fun name(): String => "Fib Loop Memory (n=20)"

  fun ref apply() =>
    try
      DoNotOptimise[USize](FibUtil.fib_loop_memory(_n)?)
      DoNotOptimise.observe()
    end

////////////////////////////////////////////////////////////////////////////////
// Main - Register benchmarks
////////////////////////////////////////////////////////////////////////////////

actor Main is BenchmarkList
  """
  The Main actor implements `BenchmarkList`, which provides a `benchmarks` method
  used by PonyBench to discover and run all our registered benchmarks.
  """
  new create(env: Env) =>
    // Create a PonyBench runner (assuming pony-bench usage).
    // This will call `benchmarks()` below to get our list of benchmarks.
    PonyBench(env, this)

  fun tag benchmarks(bench: PonyBench) =>
    // Register each benchmark class with PonyBench
    bench(FibRecBenchmark)
    bench(FibRecMemoBenchmark)
    bench(FibLoopBenchmark)
    bench(FibLoopMemBenchmark)
