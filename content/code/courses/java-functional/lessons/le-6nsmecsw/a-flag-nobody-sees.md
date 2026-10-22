---
title: A flag nobody sees
version: 1
---

**When one thread writes a field and another reads it, Java does not promise that the reader ever sees
the new value, unless something in the program creates that promise.** That sentence is the whole
lesson, and it contradicts the picture most programmers carry: one memory, every thread looking at it.
The picture is wrong in a way you can run:

```java
// Stop.java: a worker that waits for a flag, and a main thread that sets it
public class Stop {
    static boolean stop = false;

    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(() -> {
            long spins = 0;
            while (!stop) {
                spins++;
            }
            System.out.println("worker saw stop after " + spins + " spins");
        });
        worker.start();
        Thread.sleep(1000);
        stop = true;
        System.out.println("main set stop = true");
        worker.join(3000);
        System.out.println("worker still running after 3 s: " + worker.isAlive());
        System.exit(0);
    }
}
```

```
ana@vm:~/fp/memory$ java Stop.java
main set stop = true
worker still running after 3 s: true
```

`main` set `stop` to `true` and said so. **The worker never noticed**: three seconds later it was still
spinning, and it would have spun forever if `System.exit` had not ended the program. The line that
should have reported the number of spins never printed.

## The compiler was allowed to do it

The loop body reads `stop` and does nothing that could change it. Nothing in the program says another
thread may change it either. So the just-in-time compiler, once the loop became hot, was entitled to
read `stop` once, keep the value in a register, and turn the loop into `while (true)`. **That is not a
bug in the JVM; it is an optimisation the language explicitly permits**, and the same freedom is what
lets a single-threaded loop run fast. `-Xint` runs the same program with the JIT switched off, every
bytecode interpreted:

```
ana@vm:~/fp/memory$ java -Xint Stop.java
main set stop = true
worker saw stop after 160503205 spins
worker still running after 3 s: false
```

Interpreted, the loop read the field on every turn and saw the change. **The same source is correct or
hangs depending on how the JVM chose to run it**, which is exactly what makes this kind of bug survive
testing: it depends on how hot the code is, on the processor, and on the version of the compiler.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two threads on two cores. main writes stop = true to the shared field in memory. The worker's compiled loop read stop once into a register and keeps testing the register, which still says false, so it never reads the field again and never sees the new value.\"><defs><marker id=\"cache-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"cache-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"cache-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">main</text><text x=\"130.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">stop = true</text><rect x=\"480\" y=\"20\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">worker</text><text x=\"590.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">while (!register)</text><rect x=\"250\" y=\"140\" width=\"220\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">shared memory</text><text x=\"360.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">stop = true</text><rect x=\"530\" y=\"140\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">register</text><text x=\"590.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">false</text><path d=\"M130 90 L130 170 L246 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#cache-ah-phosphor)\"></path><path d=\"M590 90 L590 136\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#cache-ah-amber)\" marker-start=\"url(#cache-ah-amber)\"></path><path d=\"M470 160 L520 160\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#cache-ah-paperdim)\"></path><text x=\"495\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read once</text></svg>", "caption": "Nothing forced the worker to read the field again, so the compiler kept the first value it read."}
```

The fix is one word, `volatile`, on the field, and lesson 13 is about what that word does and does not
promise. Before reaching for it, the next section shows the second half of the problem: not only
whether a write is seen, but in what order.
