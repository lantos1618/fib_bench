use criterion::{black_box, criterion_group, criterion_main, Criterion};
use pony_test::FibUtil;
use std::collections::HashMap;

fn fibonacci_benchmark(c: &mut Criterion) {
    let n = 20; // Same as in Pony version

    c.bench_function("Fib Rec (n=20)", |b| {
        b.iter(|| FibUtil::fib_rec(black_box(n)))
    });

    c.bench_function("Fib Rec Memo (n=20)", |b| {
        b.iter_with_setup(
            || HashMap::new(),
            |mut cache| FibUtil::fib_rec_memo(black_box(n), &mut cache)
        )
    });

    c.bench_function("Fib Loop (n=20)", |b| {
        b.iter(|| FibUtil::fib_loop(black_box(n)))
    });

    c.bench_function("Fib Loop Memory (n=20)", |b| {
        b.iter(|| FibUtil::fib_loop_memory(black_box(n)))
    });
}

criterion_group!(benches, fibonacci_benchmark);
criterion_main!(benches); 