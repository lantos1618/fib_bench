import gleam/dict
import gleam/erlang
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result

pub fn fib_rec(n: Int) -> Int {
  case n {
    n if n < 2 -> n
    _ -> fib_rec(n - 1) + fib_rec(n - 2)
  }
}

pub fn fib_rec_memo(n: Int) -> Int {
  let cache = dict.new()
  do_fib_memo(n, cache)
}

fn do_fib_memo(n: Int, cache: dict.Dict(Int, Int)) -> Int {
  case n {
    n if n < 2 -> n
    _ -> {
      case dict.get(cache, n) {
        Ok(val) -> val
        Error(_) -> {
          let val1 = do_fib_memo(n - 1, cache)
          let val2 = do_fib_memo(n - 2, cache)
          let result = val1 + val2
          dict.insert(cache, n, result)
          result
        }
      }
    }
  }
}

pub fn fib_loop(n: Int) -> Int {
  case n {
    n if n < 2 -> n
    _ -> {
      let a = 0
      let b = 1
      list.range(2, n)
      |> list.fold(
        over: _,
        from: #(a, b),
        with: fn(acc, _) {
          let #(a, b) = acc
          #(b, a + b)
        },
      )
      |> fn(result) {
        let #(_, b) = result
        b
      }
    }
  }
}

pub fn fib_loop_memory(n: Int) -> Int {
  case n {
    n if n < 2 -> n
    _ -> {
      let sequence =
        list.range(0, n)
        |> list.fold(from: [0, 1], with: fn(acc, _) {
          let last = list.first(acc) |> result.unwrap(0)
          let second_last = list.first(list.drop(acc, 1)) |> result.unwrap(0)
          [last + second_last, last, ..acc]
        })
      list.first(sequence) |> result.unwrap(0)
    }
  }
}

fn benchmark(name: String, iterations: Int, f: fn() -> a) -> Nil {
  let start = erlang.system_time(erlang.Millisecond)
  list.range(1, iterations)
  |> list.each(fn(_) { f() })
  let end = erlang.system_time(erlang.Millisecond)
  let duration = end - start
  let avg = int.to_float(duration) /. int.to_float(iterations)
  io.println(
    name
    <> ": "
    <> float.to_string(avg)
    <> "ms (avg over "
    <> int.to_string(iterations)
    <> " iterations)",
  )
}

pub fn main() {
  let n = 20
  let iterations = 1000

  io.println("Running Fibonacci benchmarks...")
  benchmark("Fib Rec (n=20)", iterations, fn() { fib_rec(n) })
  benchmark("Fib Rec Memo (n=20)", iterations, fn() { fib_rec_memo(n) })
  benchmark("Fib Loop (n=20)", iterations, fn() { fib_loop(n) })
  benchmark("Fib Loop Memory (n=20)", iterations, fn() { fib_loop_memory(n) })
  io.println("Done!")
}
