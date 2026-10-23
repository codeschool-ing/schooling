---
title: The Lock interface
version: 1
---

**`java.util.concurrent.locks.Lock` does what `synchronized` does, as an object with methods**, and the
methods add three things the keyword cannot: give up after a time limit, stop waiting when interrupted,
and check without waiting. `ReentrantLock` is the implementation you will use. Its price is that the
release is no longer automatic, so it always goes in a `finally`:

```java
// TryLock.java: lock with a time limit, and the finally that always unlocks
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantLock;

public class TryLock {
    static final ReentrantLock stockLock = new ReentrantLock();

    static void reserve(String who, long holdMs) throws InterruptedException {
        if (stockLock.tryLock(200, TimeUnit.MILLISECONDS)) {
            try {
                System.out.println(who + ": got the lock, holding it " + holdMs + " ms");
                Thread.sleep(holdMs);
            } finally {
                stockLock.unlock();
            }
        } else {
            System.out.println(who + ": gave up after 200 ms, stock is busy");
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Thread slow = Thread.ofPlatform().start(() -> run("slow", 1000));
        Thread.sleep(50);
        Thread hurried = Thread.ofPlatform().start(() -> run("hurried", 10));
        slow.join();
        hurried.join();
        Thread late = Thread.ofPlatform().start(() -> run("late", 10));
        late.join();
        System.out.println("held now: " + stockLock.isLocked());
    }

    static void run(String who, long holdMs) {
        try {
            reserve(who, holdMs);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

```
ana@vm:~/fp/locks$ java TryLock.java
slow: got the lock, holding it 1000 ms
hurried: gave up after 200 ms, stock is busy
late: got the lock, holding it 10 ms
held now: false
```

`slow` took the lock and held it for a second. `hurried` asked 50 ms later, waited its 200 ms, and
**gave up with a message**, where a `synchronized` block would have waited the whole second without a
word. `late`, after both had finished, got the lock at once, and `isLocked()` confirms that every
`lock` was matched by an `unlock`.

## The `finally` is not optional

With `synchronized`, leaving the block in any way, normally or by an exception, releases the lock. With
a `Lock`, **only `unlock()` releases it**, so an exception thrown between `lock` and `unlock` without a
`finally` leaves the lock held forever, and every thread that asks for it next waits forever. The shape
above, acquire, then `try`, then the work, then `unlock` in `finally`, is the only safe one.

| need | use |
|---|---|
| plain mutual exclusion | `synchronized`: shorter, and cannot leak |
| give up after a time limit | `tryLock(time, unit)` |
| stop waiting when the thread is interrupted | `lockInterruptibly()` |
| many readers, few writers | `ReentrantReadWriteLock`: readers share, a writer is alone |

Since Java 24, a virtual thread waiting inside `synchronized` no longer holds on to its carrier thread,
which removed the main reason virtual-thread code used to prefer `ReentrantLock`; lesson 17 explains
what that means. Choose by the table, not by habit.
