---
title: What it changes
version: 1
---

**Virtual threads do not make any single task faster. They make it cheap to have a great many tasks
waiting at once**, and most of what a server does is wait. Ten thousand requests, each spending 100 ms
waiting for a database and almost nothing computing, run on a pool of a hundred platform threads and on a
virtual thread each:

```java
// Throughput.java: ten thousand waiting tasks, on a pool of 100 and on virtual threads
import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Throughput {
    static void handleRequest() {
        try {
            Thread.sleep(Duration.ofMillis(100));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    static long run(ExecutorService executor) {
        long start = System.nanoTime();
        try (executor) {
            for (int i = 0; i < 10_000; i++) {
                executor.submit(Throughput::handleRequest);
            }
        }
        return (System.nanoTime() - start) / 1_000_000;
    }

    public static void main(String[] args) {
        System.out.println("pool of 100 platform threads: " + run(Executors.newFixedThreadPool(100)) + " ms");
        System.out.println("one virtual thread per task:  " + run(Executors.newVirtualThreadPerTaskExecutor()) + " ms");
    }
}
```

```
ana@vm:~/fp/virtual$ java Throughput.java
pool of 100 platform threads: 10027 ms
one virtual thread per task:  187 ms
```

**Ten seconds against under a fifth of one.** The pool ran 100 tasks at a time, each waiting 100 ms, so
ten thousand took a hundred rounds, while the four processors sat almost idle. With a virtual thread per
task, all ten thousand waited at the same time, and the batch took about one wait plus the cost of
starting the threads: 187 ms. **Fifty times faster, on the same processors, with the same code inside
`handleRequest`.** Nothing in the task changed; only how many of them could wait at once.

## The style it brings back

Before virtual threads, a server that wanted to keep ten thousand requests in flight with a few hundred
threads had to stop blocking: every call to a database or another service returned a future, and the
code became chains of `thenApply` and `thenCompose`, lesson 16 section 05 stretched over a whole
program, with stack traces that no longer showed who called whom. **Virtual threads make the plain
blocking style affordable again**: one thread per request, code that reads top to bottom, a `try`/`catch`
around a call that fails, and a stack trace that says where. That is what "what changes with Project Loom"
means in practice, and it is why frameworks such as Spring Boot and Helidon offer to run each request on a
virtual thread.
