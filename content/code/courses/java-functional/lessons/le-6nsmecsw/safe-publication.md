---
title: Publishing an object safely
version: 1
---

**Handing an object to another thread is called publishing it, and doing it without happens-before can
show the other thread an object that is not finished.** The constructor's writes and the write of the
reference are independent writes, and section 03 showed that independent writes may be seen in the wrong
order. A thread that reads the reference through a data race may therefore see the object with some of
its fields still at their default values: `0`, `false`, `null`.

That failure is real and specified, and it is also rare on x86, which keeps writes in order with respect
to each other more strictly than the model requires. *It was not reproduced for this course*, and a test
that tried would mostly prove nothing. That is the reason to rely on the rules rather than on experiments:
**a concurrency bug that a test cannot show is still a bug on the next processor.**

## Four ways that are safe

The model guarantees safe publication when the reference travels through any of these:

- **a `final` field.** If every field of an object is `final` and the constructor does not let `this`
  escape, any thread that sees the object sees those fields initialised, even through a race. Records
  (lesson 29 of `java`) have only `final` fields, which makes an immutable record the easiest object to
  share;
- **a `volatile` field or an atomic** (lessons 13 and 15) that holds the reference;
- **a lock**: writing the reference inside `synchronized` and reading it inside `synchronized` on the
  same lock (lesson 14);
- **a concurrent collection or a `Future`**: putting it into a `ConcurrentHashMap` or a `BlockingQueue`,
  or returning it from a task (lessons 15 and 16).

## Immutability removes the question

```java
// Published.java: an immutable record shared between threads with no lock at all
import java.util.List;

public class Published {
    record PriceList(String currency, List<Long> cents) {
        PriceList {
            cents = List.copyOf(cents);
        }
    }

    static volatile PriceList current = new PriceList("BRL", List.of(3490L, 5290L));

    public static void main(String[] args) throws InterruptedException {
        Thread reader = new Thread(() -> {
            PriceList seen = current;
            System.out.println("reader sees " + seen.currency() + " " + seen.cents());
        });
        current = new PriceList("BRL", List.of(3290L, 4990L, 7990L));
        reader.start();
        reader.join();
    }
}
```

```
ana@vm:~/fp/memory$ java Published.java
reader sees BRL [3290, 4990, 7990]
```

`PriceList` cannot change after construction: its fields are `final`, and the compact constructor copies
the list into one nobody can modify. Readers never need a lock, because there is nothing that could change
under them. **To update the prices, build a new `PriceList` and replace the reference**, here through a
`volatile` field so that every reader sees either the old list or the new one, whole. This pattern,
immutable values behind one reference, is the cheapest correct way to share data between threads, and it
is the functional half of this course meeting the concurrent half.
