use std::collections::HashMap;

pub struct FibUtil;

impl FibUtil {
    pub fn fib_rec(n: usize) -> usize {
        if n < 2 {
            n
        } else {
            Self::fib_rec(n - 1) + Self::fib_rec(n - 2)
        }
    }

    pub fn fib_rec_memo(n: usize, cache: &mut HashMap<usize, usize>) -> usize {
        if n < 2 {
            return n;
        }
        
        if let Some(&result) = cache.get(&n) {
            return result;
        }
        
        let result = Self::fib_rec_memo(n - 1, cache) + Self::fib_rec_memo(n - 2, cache);
        cache.insert(n, result);
        result
    }

    pub fn fib_loop(n: usize) -> usize {
        if n < 2 {
            return n;
        }
        
        let mut a = 0;
        let mut b = 1;
        
        for _ in 2..=n {
            let tmp = a + b;
            a = b;
            b = tmp;
        }
        b
    }

    pub fn fib_loop_memory(n: usize) -> usize {
        if n < 2 {
            return n;
        }
        
        let mut arr = vec![0; n + 1];
        arr[1] = 1;
        
        for i in 2..=n {
            arr[i] = arr[i-1] + arr[i-2];
        }
        arr[n]
    }
} 