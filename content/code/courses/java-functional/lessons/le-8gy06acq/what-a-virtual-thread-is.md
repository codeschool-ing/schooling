---
title: What a virtual thread is
version: 1
---

**A virtual thread is a `java.lang.Thread` that the JVM schedules itself, instead of handing it to the
operating system.** It has a stack, a name, a state, interruption and everything else lessons 11 to 16
used. What it does not have is an operating system thread of its own. A small pool of ordinary threads,
called **carriers**, runs the virtual threads. A virtual thread is **mounted** on a carrier while it runs,
and when it blocks, on `sleep`, a lock, a socket or a queue, the JVM **unmounts** it, keeps its stack in
the heap, and gives the carrier to another virtual thread. Project Loom built them, and they became a
standard part of Java in Java 21.

```java
// Virtual.java: a virtual thread, its carrier, and the carrier it comes back on
import java.time.Duration;

public class Virtual {
    public static void main(String[] args) throws InterruptedException {
        Thread v = Thread.ofVirtual().name("lookup").start(() -> {
            System.out.println("before sleep: " + Thread.currentThread());
            try {
                Thread.sleep(Duration.ofMillis(100));
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            System.out.println("after sleep:  " + Thread.currentThread());
            System.out.println("virtual: " + Thread.currentThread().isVirtual());
        });
        v.join();
        System.out.println("main is virtual: " + Thread.currentThread().isVirtual());
    }
}
```

```
ana@vm:~/fp/virtual$ java Virtual.java
before sleep: VirtualThread[#24,lookup]/runnable@ForkJoinPool-1-worker-1
after sleep:  VirtualThread[#24,lookup]/runnable@ForkJoinPool-1-worker-1
virtual: true
main is virtual: false
```

`Thread.currentThread()` printed the virtual thread's name and, after the `@`, the carrier running it:
a worker of a fork-join pool of its own, not the common pool of lesson 9. **The same code, the same
`Thread` API**, and `isVirtual()` is the only way the code can tell. `main` is a platform thread, as
it has always been.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Time runs left to right on two carrier threads. On carrier 1, virtual thread A runs, then blocks; while A waits in the heap, B runs on carrier 1. On carrier 2, C runs, and then A resumes there when its wait is over. Below, a box labelled heap holds the stacks of the waiting virtual threads.\"><defs><marker id=\"carriers-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">carrier 1</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">carrier 2</text><rect x=\"120\" y=\"22\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">A runs</text><rect x=\"300\" y=\"22\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">B runs</text><rect x=\"120\" y=\"92\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">C runs</text><rect x=\"400\" y=\"92\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">A resumes</text><rect x=\"240\" y=\"170\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"350.0\" y=\"186.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">heap</text><text x=\"350.0\" y=\"203.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A's stack, while A sleeps</text><path d=\"M270 58 L300 166\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#carriers-ah-phosphor)\"></path><path d=\"M420 166 L470 132\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#carriers-ah-phosphor)\"></path></svg>", "caption": "A waiting virtual thread holds no carrier; it resumes on whichever carrier is free."}
```

## Mounted, unmounted

The point of the figure is the white space. While a virtual thread waits, **it occupies no carrier**:
its stack is an object in the heap, under a kilobyte for a shallow call stack as the next section
measures, and the carrier is
running somebody else. When the wait ends, the virtual thread is put back on a queue and mounted on the
next free carrier, which may be a different one from before. The scheduler has as many carriers as the
machine has processors, four here, because carriers are there to compute, and only computing needs a
processor.
