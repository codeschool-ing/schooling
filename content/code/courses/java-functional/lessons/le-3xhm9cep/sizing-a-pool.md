---
title: Sizing a pool, and what happens when it is full
version: 1
---

**How many threads a pool should have depends on what the tasks do while they run.** A task that computes
keeps a processor busy for its whole life; a task that waits for a disk, a database or another service
keeps a thread and leaves the processor idle.

| tasks | threads | why |
|---|---|---|
| compute: parsing, hashing, maths | about the number of processors, `availableProcessors()` | more threads only take turns on the same cores |
| wait most of the time: I/O, remote calls | many more than processors | each thread spends most of its life waiting |
| a mix | measure | the right number depends on the ratio of waiting to working |

A common rule of thumb for waiting work is processors × (1 + wait time / compute time): with 4 processors
and tasks that wait 90 ms for every 10 ms of work, about 40 threads. It is a starting point to measure
from, not a result. Lesson 17 makes the question mostly disappear for waiting work, by making threads so
cheap that one per task is fine.

## The queue in front of the pool

`newFixedThreadPool` puts an **unbounded** queue in front of its threads. If tasks arrive faster than the
threads finish them, the queue grows without limit, every queued task holds its data in memory, and the
first sign of trouble is an `OutOfMemoryError` far from the code that submitted too much. Lesson 15
section 04 made the same point about queues between threads. Building the pool yourself lets you bound
the queue and decide what happens when it is full:

```java
// Bounded.java: a pool with a bounded queue, and a full queue that refuses work
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

public class Bounded {
    public static void main(String[] args) throws InterruptedException {
        ThreadPoolExecutor pool = new ThreadPoolExecutor(
                2, 2, 0, TimeUnit.SECONDS,
                new ArrayBlockingQueue<>(3),
                new ThreadPoolExecutor.AbortPolicy());
        for (int n = 1; n <= 7; n++) {
            int order = n;
            try {
                pool.execute(() -> Pool.sleep(300));
                System.out.println("order " + order + " accepted, queue holds " + pool.getQueue().size());
            } catch (RejectedExecutionException e) {
                System.out.println("order " + order + " refused: the pool and its queue are full");
            }
        }
        pool.shutdown();
        pool.awaitTermination(5, TimeUnit.SECONDS);
        System.out.println("completed: " + pool.getCompletedTaskCount());
    }
}
```

```
ana@vm:~/fp/executors$ java Bounded.java
order 1 accepted, queue holds 0
order 2 accepted, queue holds 0
order 3 accepted, queue holds 1
order 4 accepted, queue holds 2
order 5 accepted, queue holds 3
order 6 refused: the pool and its queue are full
order 7 refused: the pool and its queue are full
completed: 5
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Seven orders arrive from the left. Two go straight to the pool's two threads, three wait in the bounded queue, and the last two are refused with RejectedExecutionException.\"><defs><marker id=\"pool-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"pool-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"pool-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">orders 1 to 7</text><rect x=\"190\" y=\"60\" width=\"230\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"305\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">queue of 3</text><rect x=\"203\" y=\"73\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"233.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text><rect x=\"275\" y=\"73\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4</text><rect x=\"347\" y=\"73\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"377.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">5</text><rect x=\"480\" y=\"20\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">thread 1: order 1</text><rect x=\"480\" y=\"76\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">thread 2: order 2</text><rect x=\"190\" y=\"158\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"305.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">6 and 7: refused</text><path d=\"M140 95 L186 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#pool-ah-paperdim)\"></path><path d=\"M420 95 L450 95 L450 42 L476 42\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pool-ah-phosphor)\"></path><path d=\"M450 95 L450 98 L476 98\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pool-ah-phosphor)\"></path><path d=\"M80 120 L80 178 L186 178\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#pool-ah-amber)\"></path></svg>", "caption": "Two threads and a queue of three hold five tasks; the sixth and seventh are refused out loud."}
```

Two threads and a queue of three hold five orders; the sixth and seventh were **refused, out loud**, with
`RejectedExecutionException`. That is the `AbortPolicy`, and it is the right default: the caller learns
that the system is saturated and can tell its own caller to try later. The alternative policies are worth
knowing by name: `CallerRunsPolicy` makes the submitting thread run the task itself, which slows the
producer down to the pool's pace; `DiscardPolicy` drops the task silently, which is almost never what
anybody wants and should need a comment explaining why the silence is right.

`Bounded` uses `Pool.sleep` from section 02's file, which is in the same folder.
