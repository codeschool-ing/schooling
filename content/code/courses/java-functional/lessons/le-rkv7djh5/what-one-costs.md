---
title: What one thread costs
version: 1
---

**Every platform thread is a thread of the operating system**, with its own stack of memory, its own
entry in the kernel's scheduler, and a cost to create and to switch between. A few dozen cost nothing
worth measuring. Thousands are a different matter, and the way to know how different is to start
them and look. On Linux the kernel keeps a running count of every process's threads and memory in
`/proc/self/status`, and this program reads it before and after:

```java
// Cost.java: start N platform threads that sleep, and see what the process looks like
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public class Cost {
    static String status(String field) throws Exception {
        for (String line : Files.readAllLines(Path.of("/proc/self/status"))) {
            if (line.startsWith(field)) {
                return line.replaceAll("\\s+", " ");
            }
        }
        return field + " ?";
    }

    public static void main(String[] args) throws Exception {
        int n = Integer.parseInt(args[0]);
        System.out.println("before:  " + status("Threads:") + ", " + status("VmRSS:"));
        long start = System.nanoTime();
        List<Thread> threads = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            threads.add(Thread.ofPlatform().start(() -> {
                try {
                    Thread.sleep(10_000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        System.out.printf("started: %d threads in %.0f ms%n", n, (System.nanoTime() - start) / 1e6);
        System.out.println("during:  " + status("Threads:") + ", " + status("VmRSS:"));
        for (Thread t : threads) {
            t.join();
        }
    }
}
```

```
ana@vm:~/fp/threads$ java Cost.java 1000
before:  Threads: 22, VmRSS: 123220 kB
started: 1000 threads in 185 ms
during:  Threads: 1021, VmRSS: 179372 kB
ana@vm:~/fp/threads$ java Cost.java 10000
before:  Threads: 22, VmRSS: 124084 kB
started: 10000 threads in 5501 ms
during:  Threads: 10021, VmRSS: 373624 kB
```

## Reading the numbers

`Threads:` is the operating system's own count for the process. Before anything started, the JVM
already had about twenty threads of its own: the compiler, the garbage collector, signal handling.
**The count rose by one for each `start()`**, from 22 to 1,021 and to 10,021, give or take one of
the JVM's own threads, which is the evidence that a platform thread is an operating system
thread, one for one.

`VmRSS` is the memory the process actually holds. A thousand threads added about 56 MB, some 56 KB
each, and took 185 ms to start. Ten thousand added about 250 MB and took **five and a half seconds**,
over half a millisecond a thread, just to create them. The work each one did was to sleep.

Each thread also reserves room for a stack, a megabyte by default on 64-bit Linux, changeable with
`-Xss`. Most of that reservation is address space that is never touched, which is why the resident
memory grew by far less than a megabyte per thread. But every reservation still counts against the
limits the kernel places on a process, and those limits, not memory, are usually what ends a program
that starts threads in a loop.

## What follows

A server that gives each request its own platform thread is limited to a few thousand requests in
flight at once, however little each one does, because most of a request's life is spent **waiting**:
for the database, for another service, for the network. That is the cost lessons 16 and 17 attack from
two directions. Lesson 16 reuses a fixed set of threads through a pool. Lesson 17 makes threads so cheap
that a million of them fit where ten thousand did not.
