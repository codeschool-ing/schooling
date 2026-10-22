---
title: Race conditions
version: 1
---

**A race condition is a bug whose result depends on the timing of threads.** Lesson 13's lost update is
one kind. The other common kind is **check-then-act**: a thread checks a condition, then acts on it,
and another thread changes the condition in between. Money makes the consequence plain:

```java
// Overdraft.java: two withdrawals that each check the balance first
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;

public class Overdraft {
    static class Account {
        private long cents;

        Account(long cents) {
            this.cents = cents;
        }

        boolean withdraw(long amount) {
            if (cents >= amount) {
                Thread.yield();
                cents -= amount;
                return true;
            }
            return false;
        }

        long balance() {
            return cents;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        for (int run = 1; run <= 5; run++) {
            Account account = new Account(100_000);
            CountDownLatch open = new CountDownLatch(1);
            List<Thread> tills = new ArrayList<>();
            for (int t = 0; t < 4; t++) {
                tills.add(Thread.ofPlatform().start(() -> {
                    awaitQuietly(open);
                    for (int i = 0; i < 1000; i++) {
                        account.withdraw(50);
                    }
                }));
            }
            open.countDown();
            for (Thread t : tills) {
                t.join();
            }
            System.out.println("run " + run + ": balance " + account.balance());
        }
    }

    static void awaitQuietly(CountDownLatch latch) {
        try {
            latch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

```
ana@vm:~/fp/locks$ java Overdraft.java
run 1: balance -100
run 2: balance -100
run 3: balance -150
run 4: balance -150
run 5: balance -100
```

## Reading it

Four tills try 4,000 withdrawals of 50 cents from an account holding 100,000 cents, which covers 2,000
of them. Run on one thread, `withdraw` refuses as soon as the money runs out, and the balance ends at
exactly 0. Run on four, released together by the `CountDownLatch` from lesson 12 section 03, **the
account ended below zero in every run**: money that did not exist was paid out.

The window is the gap between `if (cents >= amount)` and `cents -= amount`. `Thread.yield()` sits in
that gap only to make it wider, by inviting the scheduler to switch threads there, so that the failure
shows up on a quiet machine; **real code has the same gap without it**, and under load it is hit just as
surely, only less often. Two tills both read a balance of 50, both pass the check, and both subtract,
leaving −50. And `cents -= amount` is itself a read-modify-write, so subtractions can also be lost,
which pushes the balance the other way.

Neither of the two shapes, check-then-act and read-modify-write, is fixed by `volatile`, because each is
**several steps that must happen together**. What they need is for one thread at a time to run the whole
sequence: mutual exclusion, which is the next section.
