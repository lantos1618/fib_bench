use pony_test::FibUtil;

fn main() {
    println!("Run 'cargo bench' to see the benchmark results!");
    
    // Example usage:
    let n = 10;
    println!("Fibonacci({}) = {}", n, FibUtil::fib_loop(n));
}
