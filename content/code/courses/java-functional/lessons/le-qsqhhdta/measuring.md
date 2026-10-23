---
title: Measuring, not guessing
version: 1
---

**A parallel stream is faster only when the work per element, times the number of elements, is large
enough to pay for splitting, scheduling and combining.** The only reliable way to know is to measure,
and the measurement has to be honest about the JVM: the first runs of any code are slower, while it is
interpreted and before the compiler has optimised it. This program runs each version five times and
keeps the best:

```java
// Primes.java: the same count, sequential and parallel, timed
import java.util.function.LongSupplier;
import java.util.stream.IntStream;

public class Primes {
    static boolean isPrime(int n) {
        if (n < 2) {
            return false;
        }
        for (int d = 2; (long) d * d <= n; d++) {
            if (n % d == 0) {
                return false;
            }
        }
        return true;
    }

    static void time(String label, LongSupplier work) {
        long best = Long.MAX_VALUE;
        long result = 0;
        for (int run = 0; run < 5; run++) {
            long start = System.nanoTime();
            result = work.getAsLong();
            best = Math.min(best, System.nanoTime() - start);
        }
        System.out.printf("%-22s %8d   best of 5: %9.3f ms%n", label, result, best / 1e6);
    }

    public static void main(String[] args) {
        System.out.println("processors: " + Runtime.getRuntime().availableProcessors());
        time("primes, sequential", () -> IntStream.range(0, 2_000_000).filter(Primes::isPrime).count());
        time("primes, parallel", () -> IntStream.range(0, 2_000_000).parallel().filter(Primes::isPrime).count());
        time("small sum, loop", () -> {
            long s = 0;
            for (int i = 0; i < 100; i++) {
                s += i;
            }
            return s;
        });
        time("small sum, sequential", () -> IntStream.range(0, 100).asLongStream().sum());
        time("small sum, parallel", () -> IntStream.range(0, 100).parallel().asLongStream().sum());
    }
}
```

```
ana@vm:~/fp/parallel$ java Primes.java
processors: 4
primes, sequential       148933   best of 5:   283.981 ms
primes, parallel         148933   best of 5:    81.114 ms
small sum, loop            4950   best of 5:     0.001 ms
small sum, sequential      4950   best of 5:     0.014 ms
small sum, parallel        4950   best of 5:     0.050 ms
```

**The times are one run on this machine**, and yours will differ; the ratios are what to read.

## Where it helped

Counting the primes below two million tests each number by trial division, which is real work per
element, and the elements are an `IntStream.range`, the source that splits best. The parallel version
was about three and a half times faster on four processors, 81 ms against 284. That is the case parallel streams were built
for: **many elements, expensive work on each, no shared state**, and a source that divides evenly.
Four processors did not give a speed-up of four, because splitting, starting the workers and combining
the counts cost something, and the work in the larger numbers is unevenly spread.

## Where it got in the way

Summing a hundred small numbers is the opposite. The loop took about a microsecond and the
sequential stream 14, and the parallel stream took 50, **to do about a microsecond of arithmetic**:
the cost was handing pieces to other threads and waiting for them. Most streams in
ordinary business code look like this one, a few dozen elements and cheap lambdas, which is why
`parallel()` is not a switch to flip everywhere and see what happens.

## How to measure your own case

- **warm up, and repeat**: the first run includes the JIT compiling the code. Keeping the best of
  several runs, as `time` does, is the cheapest correction;
- **measure on data the size of production**: a pipeline that loses on a thousand elements can win
  on ten million, and the other way round;
- **for decisions that matter, use JMH**, the OpenJDK project's harness for benchmarks, which handles
  warm-up, dead-code elimination and statistics properly. A loop with `nanoTime` is a first look, not
  a verdict.
