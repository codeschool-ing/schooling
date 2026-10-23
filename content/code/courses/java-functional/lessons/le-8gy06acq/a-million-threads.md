---
title: A million threads
version: 1
---

**Lesson 11 section 04 started ten thousand platform threads that slept, and it took five and a half
seconds and about 250 MB.** The same experiment with virtual threads, a hundred times larger:

```java
// Million.java: one million virtual threads that sleep, and the process around them
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Million {
    static String status(String field) throws Exception {
        for (String line : Files.readAllLines(Path.of("/proc/self/status"))) {
            if (line.startsWith(field)) {
                return line.replaceAll("\\s+", " ");
            }
        }
        return field + " ?";
    }

    public static void main(String[] args) throws Exception {
        int n = 1_000_000;
        System.out.println("before:    " + status("Threads:") + ", " + status("VmRSS:"));
        long start = System.nanoTime();
        try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < n; i++) {
                executor.submit(() -> {
                    Thread.sleep(Duration.ofSeconds(2));
                    return null;
                });
            }
            System.out.printf("submitted: %d virtual threads in %d ms%n", n, (System.nanoTime() - start) / 1_000_000);
            System.out.println("during:    " + status("Threads:") + ", " + status("VmRSS:"));
        }
        System.out.printf("finished:  all of them, %d ms after the first started%n", (System.nanoTime() - start) / 1_000_000);
    }
}
```

```
ana@vm:~/fp/virtual$ java Million.java
before:    Threads: 22, VmRSS: 127388 kB
submitted: 1000000 virtual threads in 1813 ms
during:    Threads: 27, VmRSS: 1022092 kB
finished:  all of them, 9496 ms after the first started
```

## Reading the numbers

The operating system counted 22 threads before and 27 during: **a million virtual threads added five
operating system threads**, the carriers among them. Submitting them all took 1.8 seconds, about a third
of what ten thousand platform threads took in lesson 11, for a hundred times as many. Memory grew by
about 870 MB, **under a kilobyte per thread** with its stack, its task and the executor's bookkeeping,
where a platform thread cost tens of kilobytes.

The last thread finished 9.5 seconds after the first started, although each slept only two. Waking and
ending a million threads is real work for four processors, and the program measured it rather than
assuming it away. A million threads are cheap, not free.

`Executors.newVirtualThreadPerTaskExecutor()` gives each submitted task a new virtual thread, and closing
it in try-with-resources waits for all of them, exactly like the pools of lesson 16. **There is no pool
of virtual threads, and there should never be one**: a pool exists to reuse something expensive, and a
virtual thread is cheaper to create than to look after. One new virtual thread per task is the intended
use.

The task is a `Callable`, because of the `return null`: `Thread.sleep` throws `InterruptedException`, a
`Callable` may throw it, and a `Runnable` may not (lesson 2 section 05).
