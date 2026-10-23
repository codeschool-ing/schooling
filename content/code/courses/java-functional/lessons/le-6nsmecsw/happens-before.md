---
title: Happens-before
version: 1
---

**The Java memory model is a set of rules about which writes a read is allowed to see.** Its central
idea is a relation called **happens-before**: if action A happens-before action B, then everything A wrote
is visible to B, and B cannot appear to have run before A. When two actions in different threads have no
happens-before between them, and at least one writes a variable the other touches, the program has a
**data race**, and the model promises almost nothing about what is read.

The relation is created by a short list of things, and each concurrency tool in Java is one of them:

| this | happens-before | so |
|---|---|---|
| an action in a thread | every later action in the same thread | one thread sees its own work in order |
| `t.start()` | every action in `t` | the new thread sees what was written before it started |
| every action in `t` | another thread's return from `t.join()` | after `join`, the caller sees all the thread's results |
| releasing a lock (`synchronized` exit, `unlock`) | the next acquisition of the same lock | lesson 14 |
| a write to a `volatile` field | every later read of that field | lesson 13 |
| the end of a constructor's writes to `final` fields | any thread that sees the object | section 05 |
| putting into a concurrent collection, completing a `Future` | taking it out, reading the result | lessons 15 and 16 |

The relation is **transitive**: if A happens-before B and B happens-before C, then A happens-before C. That
is what lets one `volatile` write publish a whole batch of ordinary writes made before it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two timelines, thread A above and thread B below. In A, x = 1 comes before the release of a lock. In B, the acquisition of the same lock comes before reading x. An arrow from the release to the acquisition is the happens-before edge, and because the relation is transitive, x = 1 happens-before the read, which sees 1.\"><defs><marker id=\"hb-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"hb-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">thread A</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">thread B</text><path d=\"M90 40 L116 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M440 40 L700 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M90 150 L326 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M680 150 L700 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><rect x=\"120\" y=\"22\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">x = 1</text><rect x=\"300\" y=\"22\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">release lock</text><rect x=\"330\" y=\"132\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">acquire lock</text><rect x=\"540\" y=\"132\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">r = x  // 1</text><path d=\"M240 40 L296 40\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#hb-ah-paperdim)\"></path><path d=\"M370 58 L400 128\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#hb-ah-phosphor)\"></path><path d=\"M470 150 L536 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#hb-ah-paperdim)\"></path><text x=\"460\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">happens-before</text></svg>", "caption": "One edge between threads, plus the order inside each thread, orders everything before it with everything after it."}
```

## Why `join` was enough in lesson 11

Every program in lesson 11 had threads write results that `main` printed afterwards, with no `volatile`
and no lock, and they were right to. **`join` creates a happens-before edge**: everything the thread did is
visible to the thread that returned from `join`. The same holds for `start`, in the other direction, which
is why a lambda can read the values its thread was given before `start`.

```java
// Joined.java: a plain field, made visible by join
public class Joined {
    static long total;

    public static void main(String[] args) throws InterruptedException {
        Thread adder = new Thread(() -> {
            for (int i = 1; i <= 1_000_000; i++) {
                total += i;
            }
        });
        adder.start();
        adder.join();
        System.out.println("total after join: " + total);
    }
}
```

```
ana@vm:~/fp/memory$ java Joined.java
total after join: 500000500000
```

`total` is an ordinary field written by one thread and read by another, and the answer is right every time,
because the read comes after `join`. Remove the `join` and the program has a data race: `main` may print 0,
a partial sum, or the full one. **A correct concurrent program is one where every pair of conflicting
accesses is ordered by happens-before**; the rest of this course's concurrency lessons are the ways to
arrange that.
