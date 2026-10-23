---
title: Executors
version: 1
---

**An `ExecutorService` separates the work from the threads that do it.** You submit tasks; the executor
decides which thread runs each one. The usual kind keeps a fixed set of threads alive and feeds them
tasks from a queue, so a thread is created once and reused for thousands of tasks, which removes the cost
lesson 11 section 04 measured.

```java
// Pool.java: ten tasks on a pool of four threads
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Pool {
    public static void main(String[] args) {
        try (ExecutorService pool = Executors.newFixedThreadPool(4)) {
            for (int n = 1; n <= 10; n++) {
                int order = n;
                pool.submit(() -> {
                    sleep(100);
                    System.out.println("order " + order + " on " + Thread.currentThread().getName());
                });
            }
            System.out.println("main: all ten submitted");
        }
        System.out.println("main: the pool has finished and shut down");
    }

    static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

```
ana@vm:~/fp/executors$ java Pool.java
main: all ten submitted
order 4 on pool-1-thread-4
order 2 on pool-1-thread-2
order 3 on pool-1-thread-3
order 1 on pool-1-thread-1
order 5 on pool-1-thread-4
order 8 on pool-1-thread-1
order 7 on pool-1-thread-3
order 6 on pool-1-thread-2
order 9 on pool-1-thread-4
order 10 on pool-1-thread-1
main: the pool has finished and shut down
```

## What happened

`main` submitted all ten tasks at once and went on; `submit` does not wait. **Only four ran at a time**,
on four threads named `pool-1-thread-1` to `pool-1-thread-4`, and the same four names served all ten
orders. The other six waited in the executor's queue until a thread was free. The orders finished in
batches of four, about 100 ms apart, which is what four workers and 100 ms of work each look like.

`int order = n;` is there for lesson 1 section 06's rule: `n` changes on every turn of the loop, so the
lambda cannot capture it, and `order` is a new effectively final variable each time.

## Shutting down

An executor's threads keep the JVM alive until the executor is shut down. Since Java 19,
`ExecutorService` is `AutoCloseable`, and **closing it in a try-with-resources** (lesson 37 of `java`)
does the right thing: it stops accepting new tasks, waits for the submitted ones to finish, and then lets
the threads end. That is why the last line printed only after every order. Before Java 19 the same took
`shutdown()` followed by `awaitTermination(...)`, and forgetting them is how a program that printed its
last line keeps running for no visible reason.

| factory | gives | for |
|---|---|---|
| `newFixedThreadPool(n)` | n threads, an unbounded queue | a known amount of parallel work |
| `newSingleThreadExecutor()` | one thread, tasks in order | work that must not overlap |
| `newScheduledThreadPool(n)` | tasks run later or repeatedly | timers, polling |
| `newVirtualThreadPerTaskExecutor()` | a new virtual thread per task | work that waits; lesson 17 |
