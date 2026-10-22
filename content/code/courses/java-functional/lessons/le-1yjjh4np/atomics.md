---
title: Atomics
version: 1
---

**An atomic variable does a read-modify-write as one indivisible operation, without a lock.** The
classes in `java.util.concurrent.atomic`, `AtomicInteger`, `AtomicLong`, `AtomicReference` and their
relatives, use an instruction the processor provides for exactly this: **compare-and-set**, which writes
a new value only if the variable still holds the value the thread last read, and reports whether it did.

```schooling-example
{
  "language": "java",
  "file": "Atomics.java",
  "parts": [
    {
      "code": "// Atomics.java: lesson 13's counter, an atomic maximum, and LongAdder\nimport java.util.ArrayList;\nimport java.util.List;\nimport java.util.concurrent.atomic.AtomicLong;\nimport java.util.concurrent.atomic.LongAdder;\n\npublic class Atomics {\n    static void onFourThreads(Runnable work) throws InterruptedException {\n        List<Thread> threads = new ArrayList<>();\n        for (int t = 0; t < 4; t++) {\n            threads.add(Thread.ofPlatform().start(work));\n        }\n        for (Thread t : threads) {\n            t.join();\n        }\n    }"
    },
    {
      "code": "\n    public static void main(String[] args) throws InterruptedException {\n        AtomicLong count = new AtomicLong();\n        onFourThreads(() -> {\n            for (int i = 0; i < 1_000_000; i++) {\n                count.incrementAndGet();\n            }\n        });\n        System.out.println(\"count: \" + count.get() + \" of 4000000\");",
      "note": "Lesson 13's counter with `AtomicLong`. `incrementAndGet` reads, adds and writes as one operation, so no increment can be lost, and there is no lock anywhere."
    },
    {
      "code": "\n        AtomicLong largest = new AtomicLong(Long.MIN_VALUE);\n        onFourThreads(() -> {\n            for (long order = 1; order <= 1000; order++) {\n                long candidate = order * 37 % 10_007;\n                long seen = largest.get();\n                while (candidate > seen && !largest.compareAndSet(seen, candidate)) {\n                    seen = largest.get();\n                }\n            }\n        });\n        System.out.println(\"largest: \" + largest.get());",
      "note": "A running maximum, written by hand with `compareAndSet`. If another thread changed `largest` between the `get` and the set, the set fails, the loop reads the new value, and decides again. This retry loop is how every atomic works inside."
    },
    {
      "code": "\n        LongAdder hits = new LongAdder();\n        onFourThreads(() -> {\n            for (int i = 0; i < 1_000_000; i++) {\n                hits.increment();\n            }\n        });\n        System.out.println(\"hits: \" + hits.sum());\n    }\n}\n",
      "note": "`LongAdder` keeps several counters internally and adds them up only when `sum()` is called, so four threads rarely compete for the same one. It suits counters written far more often than they are read."
    }
  ],
  "output": "count: 4000000 of 4000000\nlargest: 9993\nhits: 4000000"
}
```

## What compare-and-set buys, and what it costs

The counter reached four million, the same answer as the `synchronized` version of lesson 14, without
any thread ever waiting for a lock. **A thread that loses a compare-and-set does not block; it retries**,
which is why atomics are called lock-free. Under light contention the retry almost never happens and an
atomic is cheaper than a lock. Under heavy contention many threads retry against the same variable, and
`LongAdder` exists to spread them out over several cells.

The `largest` loop also shows the limit of an atomic: **it protects one variable.** Keeping a minimum and
a maximum consistent with each other, or a balance and the list of transactions that produced it, is
two variables that must change together, and that needs a lock or a single immutable object behind an
`AtomicReference`, replaced as a whole (lesson 12 section 05).

`updateAndGet` and `accumulateAndGet` write the retry loop for you: `largest.accumulateAndGet(candidate,
Math::max)` does what the hand-written loop did, in one line. The loop is shown because every atomic
operation is that loop underneath, and knowing it explains why the function you pass **may be called more
than once** and must have no side effects.
