---
title: Choosing a concurrent collection
version: 1
---

**`java.util.concurrent` has a thread-safe answer for most of the ways threads share data, and choosing
one is choosing how the sharing works.** The lock you would have written is already inside it, written by
people who measured it.

| the sharing | use | notes |
|---|---|---|
| one counter, many writers | `AtomicLong`, or `LongAdder` if writes far outnumber reads | section 02 |
| one reference, replaced as a whole | `AtomicReference` holding an immutable object | lesson 12 section 05 |
| a map many threads read and update | `ConcurrentHashMap`, updating with `merge`, `compute` | section 03 |
| work handed from producers to consumers | `ArrayBlockingQueue` (bounded) or `LinkedBlockingQueue` | section 04 |
| a list read far more often than changed | `CopyOnWriteArrayList` | below |
| wait until N things have happened | `CountDownLatch` | lesson 12 section 03 |
| at most N threads at once in some code | `Semaphore` | below |

## Two more, briefly

```java
// TwoMore.java: a list that copies on write, and a semaphore that admits two at a time
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicInteger;

public class TwoMore {
    public static void main(String[] args) throws InterruptedException {
        List<String> listeners = new CopyOnWriteArrayList<>(List.of("audit", "email"));
        for (String l : listeners) {
            listeners.add(l + "-copy");
        }
        System.out.println(listeners);

        Semaphore printers = new Semaphore(2);
        AtomicInteger inside = new AtomicInteger();
        AtomicInteger most = new AtomicInteger();
        Thread[] jobs = new Thread[6];
        for (int j = 0; j < jobs.length; j++) {
            jobs[j] = Thread.ofPlatform().start(() -> {
                try {
                    printers.acquire();
                    try {
                        most.accumulateAndGet(inside.incrementAndGet(), Math::max);
                        Thread.sleep(50);
                        inside.decrementAndGet();
                    } finally {
                        printers.release();
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        for (Thread t : jobs) {
            t.join();
        }
        System.out.println("six jobs, at most " + most.get() + " printing at once");
    }
}
```

```
ana@vm:~/fp/concurrent$ java TwoMore.java
[audit, email, audit-copy, email-copy]
six jobs, at most 2 printing at once
```

**`CopyOnWriteArrayList` copies its whole array on every change**, so a loop over it walks the copy it
started with and never sees a `ConcurrentModificationException`: the loop above added to the list while
iterating, and finished, having seen only the two original elements. Every `add` costs a full copy, which
is fine for a list of listeners changed a few times a day and ruinous for one changed constantly.

**A `Semaphore` hands out permits.** With two permits, six jobs ran at most two at a time, and the others
waited in `acquire`. It is the right tool for limiting how many threads use a scarce resource at once:
connections to a database, calls to a service with a rate limit. Lesson 17 uses one to protect a service
from a million virtual threads.
