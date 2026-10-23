---
title: Futures
version: 1
---

**`submit` returns a `Future`: a handle on a result that does not exist yet.** `get()` waits for the task
to finish and returns what it returned. When the task is a `Callable`, a functional interface whose one
method returns a value and may throw, the `Future` carries that value back; and when the task throws, the
`Future` carries the exception back instead.

```java
// Futures.java: results, a failure that is not lost, and a timeout
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class Futures {
    public static void main(String[] args) throws InterruptedException {
        try (ExecutorService pool = Executors.newFixedThreadPool(2)) {
            Callable<Long> stock = () -> {
                Thread.sleep(200);
                return 12L;
            };
            Callable<Long> broken = () -> {
                throw new IllegalStateException("price file is missing");
            };
            Callable<Long> slow = () -> {
                Thread.sleep(5_000);
                return 0L;
            };

            Future<Long> f1 = pool.submit(stock);
            Future<Long> f2 = pool.submit(broken);
            System.out.println("submitted; f1 done yet? " + f1.isDone());
            System.out.println("stock: " + f1.get());

            try {
                f2.get();
            } catch (ExecutionException e) {
                System.out.println("broken task failed: " + e.getCause());
            }

            Future<Long> f3 = pool.submit(slow);
            try {
                f3.get(300, TimeUnit.MILLISECONDS);
            } catch (TimeoutException e) {
                System.out.println("gave up waiting after 300 ms; cancelled: " + f3.cancel(true));
            }
        } catch (ExecutionException e) {
            throw new IllegalStateException(e);
        }
    }
}
```

```
ana@vm:~/fp/executors$ java Futures.java
submitted; f1 done yet? false
stock: 12
broken task failed: java.lang.IllegalStateException: price file is missing
gave up waiting after 300 ms; cancelled: true
```

## Three outcomes of `get`

**A result.** `f1.isDone()` was `false` right after `submit`, and `f1.get()` waited the 200 ms and
returned 12. `get` is how one thread waits for another's answer, with the happens-before edge built in
(lesson 12 section 04): whatever the task wrote is visible after `get` returns.

**A failure, kept.** The broken task threw, and the exception did not vanish into a log, as a thread's
did in lesson 11 section 05. **`get` threw `ExecutionException`, with the task's own exception as its
cause.** Whoever asks for the result learns that there is none and why; a failure cannot be silent unless
somebody never asks, which is a reason to keep every `Future` you submit until you have looked at it.

**A wait with a limit.** `get(300, MILLISECONDS)` gave up with `TimeoutException`, and `cancel(true)`
interrupted the task, which was asleep and stopped at once. Without the limit, a task that hangs makes
its caller hang too. Cancelling relies on the task responding to interruption (lesson 11 section 03): a
task that ignores it keeps running after it has been cancelled.
