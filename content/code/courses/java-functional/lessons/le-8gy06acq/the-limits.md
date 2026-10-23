---
title: The limits
version: 1
---

**Virtual threads remove the cost of a thread. They do not remove the cost of the work, nor the limits of
the things the work talks to.** Three rules follow, and one rule that recently stopped being true.

- **Computing is not helped.** A task that keeps a processor busy for its whole life gains nothing from
  being virtual, because the carriers are as many as the processors. Lesson 9's prime counting would run
  no faster on a million virtual threads than on four.
- **Never pool them.** Section 03 said it; a fixed pool of virtual threads brings back the queue in front
  of the pool and none of the reasons for it.
- **A scarce resource still needs a limit.** A million virtual threads can call a database that accepts
  twenty connections a million times at once. The thread no longer limits you, so something else must:
  a `Semaphore` (lesson 15 section 05) around the call, or the connection pool's own bound.

```java
// Limited.java: ten thousand virtual threads, at most twenty inside the service at once
import java.time.Duration;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicInteger;

public class Limited {
    static final Semaphore connections = new Semaphore(20);
    static final AtomicInteger inside = new AtomicInteger();
    static final AtomicInteger most = new AtomicInteger();

    static void query() throws InterruptedException {
        connections.acquire();
        try {
            most.accumulateAndGet(inside.incrementAndGet(), Math::max);
            Thread.sleep(Duration.ofMillis(10));
            inside.decrementAndGet();
        } finally {
            connections.release();
        }
    }

    public static void main(String[] args) {
        long start = System.nanoTime();
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < 10_000; i++) {
                executor.submit(() -> {
                    query();
                    return null;
                });
            }
        }
        System.out.printf("10000 queries, at most %d at once, %d ms%n", most.get(), (System.nanoTime() - start) / 1_000_000);
    }
}
```

```
ana@vm:~/fp/virtual$ java Limited.java
10000 queries, at most 20 at once, 5212 ms
```

Ten thousand virtual threads waited for a permit, and **never more than twenty were inside the service**.
The total time is what twenty connections allow: 10,000 queries of 10 ms, twenty at a time, is at least
five seconds, and the run took 5,212 ms.

## Pinning, and what Java 24 changed

A virtual thread that cannot be unmounted while it blocks is said to be **pinned**: it holds its carrier
for the whole wait, like a platform thread. Until Java 24, blocking inside a `synchronized` block pinned
it, and a few hundred virtual threads sleeping inside `synchronized` could hold every carrier and stall
the rest. The following program runs it on this machine's Java 25, and then, to show the old behaviour,
on the Java 21 that this machine also has (lesson 1 section 03); you do not need Java 21 to follow the
course.

```java
// Pinning.java: a thousand virtual threads each sleeping inside synchronized
import java.util.concurrent.Executors;

public class Pinning {
    public static void main(String[] args) {
        long start = System.nanoTime();
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < 1000; i++) {
                Object lock = new Object();
                executor.submit(() -> {
                    synchronized (lock) {
                        try {
                            Thread.sleep(100);
                        } catch (InterruptedException e) {
                            Thread.currentThread().interrupt();
                        }
                    }
                });
            }
        }
        System.out.printf("Java %d: %d ms%n", Runtime.version().feature(), (System.nanoTime() - start) / 1_000_000);
    }
}
```

```
ana@vm:~/fp/virtual$ java Pinning.java
Java 25: 120 ms
ana@vm:~/fp/virtual$ /usr/lib/jvm/java-21-openjdk-amd64/bin/java Pinning.java
Java 21: 25057 ms
```

On Java 25 the thousand sleeps overlapped and the run took 120 ms. **On Java 21 the same program took 25
seconds**: each sleeping thread held one of the four carriers, so the sleeps ran four at a time, 250
rounds of 100 ms. Java 24 removed that pin for `synchronized`, which is why the old advice to replace
`synchronized` with `ReentrantLock` in virtual-thread code no longer applies (lesson 14 section 04). Blocking in native code still pins, as do a few rarer cases; the JDK's
`jdk.VirtualThreadPinned` event in Java Flight Recorder reports each one with its stack.
