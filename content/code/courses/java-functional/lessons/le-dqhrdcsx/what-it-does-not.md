---
title: What volatile does not do
version: 1
---

**`volatile` makes each read and each write of a field visible and ordered. It does not make a read
followed by a write into one indivisible step.** `count++` is three steps: read `count`, add one, write
`count`. Two threads can both read 41, both add one, and both write 42, and one increment is lost, even
though every read and every write was perfectly visible:

```java
// LostUpdates.java: four threads incrementing a volatile counter
import java.util.ArrayList;
import java.util.List;

public class LostUpdates {
    static volatile long count = 0;

    public static void main(String[] args) throws InterruptedException {
        for (int run = 1; run <= 3; run++) {
            count = 0;
            List<Thread> threads = new ArrayList<>();
            for (int t = 0; t < 4; t++) {
                threads.add(Thread.ofPlatform().start(() -> {
                    for (int i = 0; i < 1_000_000; i++) {
                        count++;
                    }
                }));
            }
            for (Thread t : threads) {
                t.join();
            }
            System.out.println("run " + run + ": " + count + " of 4000000");
        }
    }
}
```

```
ana@vm:~/fp/volatile$ java LostUpdates.java
run 1: 1281588 of 4000000
run 2: 1190673 of 4000000
run 3: 1672481 of 4000000
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two threads incrementing count, which starts at 41. Thread 1 reads 41. Thread 2 reads 41. Thread 1 adds one and writes 42. Thread 2 adds one and writes 42. Two increments ran and count went up by one.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">thread 1</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">thread 2</text><rect x=\"110\" y=\"30\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">read 41</text><rect x=\"260\" y=\"120\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">read 41</text><rect x=\"410\" y=\"30\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">write 42</text><rect x=\"560\" y=\"120\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">write 42</text><rect x=\"110\" y=\"180\" width=\"580\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">count: 41 before, 42 after two increments</text></svg>", "caption": "Both reads came before either write: two increments, one result."}
```

## Why the count comes out short

Every run lost more than half of its four million increments, a different number each time. **`volatile` made the
lost updates visible to everyone; it did not prevent them.** Between one thread's read and its write,
other threads read the same value and wrote over each other. This shape, read, decide, write, has a name,
**read-modify-write**, and so does the bug, a **lost update**. It is the same race that lost elements from
the shared `ArrayList` in lesson 9 section 04, one level down.

Two tools fix it, and they are the next two lessons:

- **a lock** (lesson 14) makes the three steps run one thread at a time, so no other thread can get
  between the read and the write;
- **an atomic** (lesson 15), `AtomicLong.incrementAndGet()`, does the read, the add and the write as one
  operation of the processor, and retries if another thread got in first.

The compiler accepts `count++` on a `volatile` field without a warning, which is why this mistake is
common: the keyword reads like "safe for threads", and it is only "visible to threads".
