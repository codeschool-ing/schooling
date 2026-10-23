---
title: Choosing by who leaves next
version: 1
---

Lesson 32 chose a collection by the question asked of it. For everything in this lesson the question
is the same, *which one is next?*, and the three possible answers are three classes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Three ways to take the next element. A FIFO queue, ArrayDeque used with offer and poll: elements enter at the tail and leave at the head, first in first out. A LIFO stack, ArrayDeque used with push and pop: elements enter and leave at the same end, last in first out. A priority queue, PriorityQueue: elements enter in any order and the smallest by its comparator leaves first.\"><defs><marker id=\"jv33-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">first in, first out</text><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ArrayDeque: offer, poll</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">last in, first out</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ArrayDeque: push, pop</text><text x=\"20\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">smallest first</text><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">PriorityQueue: offer, poll</text><rect x=\"330\" y=\"20\" width=\"76\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"368\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana</text><rect x=\"410\" y=\"20\" width=\"76\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bruno</text><rect x=\"490\" y=\"20\" width=\"76\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"528\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Carla</text><path d=\"M620 37 H574\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv33-a)\"></path><text x=\"660\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">offer</text><path d=\"M326 37 H280\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv33-a)\"></path><text x=\"258\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">poll</text><rect x=\"330\" y=\"110\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"376\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">return Dune</text><rect x=\"426\" y=\"110\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"472\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lend Emma</text><rect x=\"522\" y=\"110\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"568\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lend Dune</text><path d=\"M286 120 H326\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv33-a)\"></path><text x=\"258\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">push</text><path d=\"M326 134 H286\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv33-a)\"></path><text x=\"258\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pop</text><text x=\"330\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one end does both jobs: the head</text><rect x=\"330\" y=\"200\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bruno</text><text x=\"363\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9 days</text><rect x=\"400\" y=\"200\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"433\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana</text><text x=\"433\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 days</text><rect x=\"470\" y=\"200\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"503\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Davi</text><text x=\"503\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 days</text><rect x=\"540\" y=\"200\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Carla</text><text x=\"573\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 days</text><rect x=\"610\" y=\"200\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"643\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Eva</text><text x=\"643\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 days</text><path d=\"M326 217 H286\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv33-a)\"></path><text x=\"258\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">poll</text><text x=\"330\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">in any order; poll takes the fewest days: Carla</text></svg>", "caption": "Three answers to \"which one is next?\". The class you choose is the answer you get."}
```

| what "next" means | declare | create |
|---|---|---|
| the one that arrived first | `Queue<E>` | `new ArrayDeque<>()` |
| the one that arrived last | `Deque<E>` | `new ArrayDeque<>()` |
| the smallest, by some order | `Queue<E>` | `new PriorityQueue<>(comparator)` |

The common belief is that `LinkedList` belongs in the first row, because it implements `Queue` and
`Deque` and because lesson 32 named a queue as its one good use. It does implement both. **It is
still slower than `ArrayDeque` at a queue's job.** The reason is the first figure of lesson 32
again: every `offer` on a linked list creates a node object, where `ArrayDeque` writes a reference
into a slot of an array it reuses, wrapping round from the end to the start.

## Measured, once

This program keeps a queue of at most a hundred numbers and pushes five million through it, on
each class, and does the whole thing twice:

```java
// QueueCost.java
import java.util.ArrayDeque;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;

public class QueueCost {
    static final int ROUNDS = 5_000_000;

    public static void main(String[] args) {
        for (int run = 1; run <= 2; run++) {
            for (Queue<Integer> q : List.<Queue<Integer>>of(new ArrayDeque<>(), new LinkedList<>())) {
                long start = System.nanoTime();
                for (int i = 0; i < ROUNDS; i++) {
                    q.offer(i);
                    if (q.size() > 100) {
                        q.poll();
                    }
                }
                long ms = (System.nanoTime() - start) / 1_000_000;
                System.out.printf("run %d  %-10s %4d ms%n", run, q.getClass().getSimpleName(), ms);
            }
        }
    }
}
```

```
ana@vm:~/queues$ java QueueCost.java
run 1  ArrayDeque   59 ms
run 1  LinkedList  338 ms
run 2  ArrayDeque   30 ms
run 2  LinkedList  495 ms
```

Times jump about between runs, and these are one run of it. **In every round `ArrayDeque` was the
faster**, by a factor of between five and sixteen here. The first round was slower than the second for
`ArrayDeque`, which is lesson 1's JIT compiler at work: the first round ran partly interpreted.
The linked list did not speed up on its second round, because what costs it is not the loop but
the five million nodes it allocates and the garbage collector that then has to clear them.

So the second and third rows of the table hold no surprise, and the first holds one: **the queue a
program reaches for is an `ArrayDeque` too**. `LinkedList` keeps one real advantage, which is that
it accepts `null` elements. Section 02 explained why a queue that answers `null` for "empty" should
not hold one anyway.

`java.util.concurrent` has more queues, `ArrayBlockingQueue` among them, built for threads that
hand work to each other and wait when the queue is empty or full. They belong to `java-functional`,
which is about concurrency; nothing in this course needs one beyond section 02's two seats.
