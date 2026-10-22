---
title: Tasks that outlive their caller
version: 1
---

**When a method starts tasks on other threads and returns, nothing ties those tasks to the method.**
Lesson 16's page asked for a price and a stock level at once. Make the price lookup fail, and see what
happens to the stock lookup that was started beside it:

```java
// Orphan.java: one lookup fails, and the other runs on with nobody waiting for it
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Orphan {
    static long price() {
        sleep(300);
        throw new IllegalStateException("price service down");
    }

    static int stock() {
        sleep(1000);
        System.out.println("stock: finished, for nobody");
        return 3;
    }

    static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) {
        long start = System.nanoTime();
        try (ExecutorService io = Executors.newVirtualThreadPerTaskExecutor()) {
            CompletableFuture<Long> p = CompletableFuture.supplyAsync(Orphan::price, io);
            CompletableFuture<Integer> s = CompletableFuture.supplyAsync(Orphan::stock, io);
            try {
                System.out.println(p.join() + " " + s.join());
            } catch (RuntimeException e) {
                System.out.printf("page failed after %d ms: %s%n", (System.nanoTime() - start) / 1_000_000, e.getCause());
            }
        }
        System.out.printf("main returned after %d ms%n", (System.nanoTime() - start) / 1_000_000);
    }
}
```

```
ana@vm:~/fp/structured$ java Orphan.java
page failed after 308 ms: java.lang.IllegalStateException: price service down
stock: finished, for nobody
main returned after 1008 ms
```

## What went wrong

The page knew it had failed after 300 ms. **The stock lookup did not know**, and ran its full second,
printed a result nobody would read, and only then let the executor close. In a server this is the shape
of a resource leak: a request that has already answered "error" goes on holding a connection, a thread
and a slot in somebody else's rate limit for work it will throw away. Cancelling `s` by hand when `p`
fails is possible, and has to be written, remembered and kept correct in every place that starts two
tasks.

The deeper problem is that **the relationship between the tasks exists only in the programmer's head**.
The code says "start two things"; it does not say "these two are parts of one job, and the job is over
when either fails". A thread dump would show the stock lookup's virtual thread with no hint of which
request it belonged to. Structured concurrency is the proposal to write that relationship into the code.
