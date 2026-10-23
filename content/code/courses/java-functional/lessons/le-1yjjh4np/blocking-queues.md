---
title: Blocking queues
version: 1
---

**A `BlockingQueue` is a handover point between threads.** A producer `put`s work in, a consumer `take`s
it out, and the queue does the waiting: `take` on an empty queue waits until something arrives, and `put`
on a full one waits until there is room. That second wait is called **backpressure**, and it is what stops
a fast producer from filling memory with work a slow consumer cannot keep up with.

```java
// Handover.java: a producer, two consumers and a bounded queue between them
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

public class Handover {
    record Order(int number, long cents) {}

    static final Order STOP = new Order(-1, 0);

    public static void main(String[] args) throws InterruptedException {
        BlockingQueue<Order> queue = new ArrayBlockingQueue<>(3);

        Runnable packer = () -> {
            try {
                while (true) {
                    Order o = queue.take();
                    if (o == STOP) {
                        System.out.println(Thread.currentThread().getName() + ": no more orders");
                        return;
                    }
                    Thread.sleep(30);
                    System.out.println(Thread.currentThread().getName() + ": packed order " + o.number());
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        };
        Thread a = Thread.ofPlatform().name("packer-a").start(packer);
        Thread b = Thread.ofPlatform().name("packer-b").start(packer);

        long start = System.nanoTime();
        for (int n = 1; n <= 8; n++) {
            queue.put(new Order(n, 1000L * n));
            System.out.printf("main: queued order %d at %d ms, %d waiting%n",
                    n, (System.nanoTime() - start) / 1_000_000, queue.size());
        }
        queue.put(STOP);
        queue.put(STOP);
        a.join();
        b.join();
    }
}
```

```
ana@vm:~/fp/concurrent$ java Handover.java
main: queued order 1 at 0 ms, 0 waiting
main: queued order 2 at 5 ms, 1 waiting
main: queued order 3 at 5 ms, 1 waiting
main: queued order 4 at 5 ms, 2 waiting
main: queued order 5 at 5 ms, 3 waiting
packer-b: packed order 1
main: queued order 6 at 32 ms, 3 waiting
packer-a: packed order 2
main: queued order 7 at 35 ms, 3 waiting
packer-b: packed order 3
main: queued order 8 at 62 ms, 3 waiting
packer-a: packed order 4
packer-b: packed order 5
packer-a: packed order 6
packer-b: packed order 7
packer-b: no more orders
packer-a: packed order 8
packer-a: no more orders
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"On the left, main as the producer, calling put. In the middle, a queue with room for three orders, all three slots full. On the right, two consumers, packer-a and packer-b, each calling take. A note under the queue says that when it is full, put waits, and when it is empty, take waits.\"><defs><marker id=\"queue-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">main</text><text x=\"85.0\" y=\"93.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">put()</text><rect x=\"220\" y=\"50\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"235\" y=\"63\" width=\"66\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"268.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">order</text><rect x=\"313\" y=\"63\" width=\"66\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">order</text><rect x=\"391\" y=\"63\" width=\"66\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">order</text><rect x=\"550\" y=\"25\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"41.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">packer-a</text><text x=\"625.0\" y=\"58.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">take()</text><rect x=\"550\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"116.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">packer-b</text><text x=\"625.0\" y=\"133.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">take()</text><path d=\"M150 85 L216 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#queue-ah-phosphor)\"></path><path d=\"M470 85 L510 85 L510 50 L546 50\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#queue-ah-phosphor)\"></path><path d=\"M510 85 L510 125 L546 125\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#queue-ah-phosphor)\"></path><text x=\"345\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">full: put waits</text><text x=\"345\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">empty: take waits</text></svg>", "caption": "The queue does the waiting: a full queue holds the producer back, an empty one holds the consumers."}
```

## Reading the timeline

`main` queued the first orders at once, until the queue held three and two packers were each busy with
one. **From then on `put` waited**, and the queue times follow the packers' pace: each new order went in
only when a packer had taken one out. Without the bound, `main` would have queued all eight in the first
millisecond, which is harmless with eight and an `OutOfMemoryError` with eight million.

The `STOP` order is a **poison pill**: an agreed value that tells a consumer there is no more work. One
per consumer, because each takes exactly one. Comparing with `==` is deliberate: it is the one object
`STOP`, not any order that happens to equal it.

The queue is also a happens-before edge (lesson 12 section 04): everything the producer wrote into an
order before `put` is visible to the consumer after `take`. That is why `Order` needs no `volatile` and
no lock, and why handing work over through a queue is safer than sharing it.
