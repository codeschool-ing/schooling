---
title: The life of a thread
version: 1
---

**A thread is always in one of a few states, and `getState()` says which.** It is `NEW` before `start`,
`RUNNABLE` while it runs or is ready to, one of three waiting states while it waits for something, and
`TERMINATED` when its `run` has returned. Watching a thread pass through them makes the vocabulary of the
next seven lessons concrete:

```java
// States.java: one thread's states, and a sleep cut short by interrupt
public class States {
    public static void main(String[] args) throws InterruptedException {
        Thread sleeper = new Thread(() -> {
            try {
                Thread.sleep(5_000);
                System.out.println("slept the whole five seconds");
            } catch (InterruptedException e) {
                System.out.println("woken early: " + e.getMessage()
                        + ", interrupted flag now " + Thread.currentThread().isInterrupted());
            }
        });
        System.out.println("before start: " + sleeper.getState());
        sleeper.start();
        Thread.sleep(200);
        System.out.println("while asleep: " + sleeper.getState());
        sleeper.interrupt();
        sleeper.join();
        System.out.println("after join:   " + sleeper.getState());
    }
}
```

```
ana@vm:~/fp/threads$ java States.java
before start: NEW
while asleep: TIMED_WAITING
woken early: sleep interrupted, interrupted flag now false
after join:   TERMINATED
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A state diagram. NEW goes to RUNNABLE when start is called. RUNNABLE goes to TIMED_WAITING on sleep, and back to RUNNABLE when the time is up or interrupt is called. RUNNABLE also goes to WAITING on join or wait, and to BLOCKED when it must wait for a lock held by another thread, returning when the wait ends. RUNNABLE goes to TERMINATED when run returns or throws.\"><defs><marker id=\"states-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">NEW</text><rect x=\"220\" y=\"90\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">RUNNABLE</text><rect x=\"590\" y=\"90\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">TERMINATED</text><path d=\"M130 112 L216 112\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-phosphor)\"></path><text x=\"173\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">start()</text><path d=\"M360 112 L586 112\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-paperdim)\"></path><text x=\"473\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">run returns or throws</text><rect x=\"400\" y=\"14\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"480.0\" y=\"30.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TIMED_WAITING</text><text x=\"480.0\" y=\"45.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sleep(ms)</text><rect x=\"400\" y=\"166\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"480.0\" y=\"182.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WAITING</text><text x=\"480.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">join(), wait()</text><rect x=\"60\" y=\"166\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"140.0\" y=\"182.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BLOCKED</text><text x=\"140.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a lock, lesson 14</text><path d=\"M330 90 L330 38 L396 38\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-paperdim)\" marker-start=\"url(#states-ah-paperdim)\"></path><path d=\"M330 134 L330 190 L396 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-paperdim)\" marker-start=\"url(#states-ah-paperdim)\"></path><path d=\"M250 134 L250 190 L224 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-paperdim)\" marker-start=\"url(#states-ah-paperdim)\"></path></svg>", "caption": "A thread is NEW once, TERMINATED once, and moves between running and the three kinds of waiting in between."}
```

## Interrupting is asking

`sleeper.interrupt()` did not stop the thread. **It set a flag on it and woke it from `sleep`**, which
answered by throwing `InterruptedException`; the thread caught it, printed a line and returned normally.
Java has no safe way to stop a thread from outside. `Thread.stop()` existed, killed a thread wherever it
happened to be, left half-updated objects behind, and was deprecated for that reason and finally made to
throw an exception in Java 20. Interruption is the replacement: **a request the thread checks at points
it chooses**, and every blocking method, `sleep`, `join`, `wait`, a lock acquired with
`lockInterruptibly`, is such a point.

Notice the second half of the printed line: the flag was already `false` inside the `catch`. Throwing
`InterruptedException` clears it. Code that catches the exception and cannot stop at once should call
`Thread.currentThread().interrupt()` to put the flag back, so that the code above it can see the request.
**Catching it and doing nothing is the classic way to make a thread impossible to stop.**

## The three waiting states

| state | the thread is | entered by |
|---|---|---|
| `TIMED_WAITING` | waiting, with a time limit | `sleep(ms)`, `join(ms)`, `wait(ms)` |
| `WAITING` | waiting, with no limit | `join()`, `wait()`, `LockSupport.park()` |
| `BLOCKED` | waiting to enter a `synchronized` block another thread holds | lesson 14 |

A thread dump, which `jcmd <pid> Thread.print` prints for a running JVM, lists every thread with its state
and the line it is on. When a program hangs, that is the first thing to read: the threads that are
`BLOCKED` and `WAITING`, and on what.
