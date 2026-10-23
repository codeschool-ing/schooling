---
title: Reordering
version: 1
---

**The compiler and the processor may execute independent reads and writes in a different order from the
one in the source, as long as the thread doing them cannot tell.** Another thread can tell. The classic
test has two threads and two variables, both starting at 0:

| thread A | thread B |
|---|---|
| `x = 1` | `y = 1` |
| `r1 = y` | `r2 = x` |

Try every interleaving of those four statements and at least one write comes before the other thread's
read, so **at least one of `r1` and `r2` must be 1**. The program below runs the test five million
times at once: each thread walks its own copies of the variables in a pair of arrays, so the two
threads race through matching positions:

```java
// Litmus.java: two writes, two reads, and the outcome that no interleaving allows
import java.util.concurrent.CountDownLatch;

public class Litmus {
    public static void main(String[] args) throws Exception {
        int n = 5_000_000;
        int[] x = new int[n], y = new int[n], r1 = new int[n], r2 = new int[n];
        CountDownLatch go = new CountDownLatch(1);
        Thread a = new Thread(() -> {
            await(go);
            for (int i = 0; i < n; i++) {
                x[i] = 1;
                r1[i] = y[i];
            }
        });
        Thread b = new Thread(() -> {
            await(go);
            for (int i = 0; i < n; i++) {
                y[i] = 1;
                r2[i] = x[i];
            }
        });
        a.start();
        b.start();
        go.countDown();
        a.join();
        b.join();

        int[][] count = new int[2][2];
        for (int i = 0; i < n; i++) {
            count[r1[i]][r2[i]]++;
        }
        System.out.println("r1=0 r2=0: " + count[0][0]);
        System.out.println("r1=0 r2=1: " + count[0][1]);
        System.out.println("r1=1 r2=0: " + count[1][0]);
        System.out.println("r1=1 r2=1: " + count[1][1]);
    }

    static void await(CountDownLatch latch) {
        try {
            latch.await();
        } catch (InterruptedException e) {
            throw new IllegalStateException(e);
        }
    }
}
```

```
ana@vm:~/fp/memory$ java Litmus.java
r1=0 r2=0: 24
r1=0 r2=1: 481
r1=1 r2=0: 4999495
r1=1 r2=1: 0
```

## Reading the four lines

Almost every pair shows one thread finishing its two statements before the other started its own,
which gives `0, 1` or `1, 0`. The two writes landing before both reads would give `1, 1`, and this run
caught none. **And 24 pairs show `0, 0`**, the outcome no interleaving can produce. In those, each thread read the other's variable before its own
write had become visible to the other. On this processor, an x86, each core holds its writes in a store
buffer for a short while before they reach memory everybody shares, and a read that follows a write to a
different address may complete first. The JIT is allowed to make the same swap on its own.

The `CountDownLatch` is the starting gun: both threads wait on it, and `countDown` releases them together.
Lesson 15 meets it again among the concurrency tools.

The numbers change on every run and are different on other processors; ARM processors reorder more than
x86 does. What does not change is the rule: **without something that orders them, the reads and writes of
two threads have no order you can rely on**. The next section is the something.
