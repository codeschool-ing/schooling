---
title: How a parallel stream splits the work
version: 1
---

**`parallel()` asks the stream to split its source into pieces, run the pipeline on the pieces in
several threads at once, and combine the partial results.** The code of the pipeline does not change.
What changes is who runs it: the thread that called the terminal operation, plus worker threads from
a pool the JVM keeps for this, the **common fork-join pool**.

The way to see that is to ask each element which thread it was processed on:

```java
// WhoWorks.java: which threads a parallel stream runs on
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ForkJoinPool;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

public class WhoWorks {
    public static void main(String[] args) {
        System.out.println("processors:            " + Runtime.getRuntime().availableProcessors());
        System.out.println("common pool workers:   " + ForkJoinPool.commonPool().getParallelism());

        Map<String, Long> sequential = IntStream.range(0, 100_000).boxed()
                .collect(Collectors.groupingBy(i -> Thread.currentThread().getName(), Collectors.counting()));
        System.out.println("sequential: " + sequential);

        Map<String, Long> parallel = IntStream.range(0, 100_000).parallel().boxed()
                .collect(Collectors.groupingByConcurrent(i -> Thread.currentThread().getName(), Collectors.counting()));
        new TreeMap<>(parallel).forEach((thread, count) -> System.out.println("  " + thread + ": " + count));
    }
}
```

```
ana@vm:~/fp/parallel$ java WhoWorks.java
processors:            4
common pool workers:   3
sequential: {main=100000}
  ForkJoinPool.commonPool-worker-1: 18750
  ForkJoinPool.commonPool-worker-2: 18750
  ForkJoinPool.commonPool-worker-3: 18750
  main: 43750
```

The sequential stream did everything on `main`. The parallel one shared the 100,000 elements between
`main` and the pool's workers. **The pool has one worker fewer than the machine has processors**,
three on four, because the thread that started the work takes part too: four threads, four
processors. The split is not even, and it changes from run to run, because a worker that finishes
its piece early steals part of another's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A tree. At the top, the range 0 to 2000. It is split in two, 0 to 1000 and 1000 to 2000, and each half is split again into quarters of 500. Each quarter is processed by one thread: main and three common pool workers. At the bottom, the four partial results are combined into one.\"><defs><marker id=\"forkjoin-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"forkjoin-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"285\" y=\"14\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0 .. 2000</text><rect x=\"125\" y=\"72\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0 .. 1000</text><rect x=\"445\" y=\"72\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1000 .. 2000</text><path d=\"M360 48 L200 68\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><path d=\"M360 48 L520 68\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><rect x=\"20\" y=\"130\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97.5\" y=\"146.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0 .. 500</text><text x=\"97.5\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">main</text><path d=\"M200 106 L97 126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><path d=\"M97 180 L360 222\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-phosphor)\"></path><rect x=\"195\" y=\"130\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272.5\" y=\"146.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">500 .. 1000</text><text x=\"272.5\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">worker-1</text><path d=\"M200 106 L272 126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><path d=\"M272 180 L360 222\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-phosphor)\"></path><rect x=\"370\" y=\"130\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447.5\" y=\"146.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1000 .. 1500</text><text x=\"447.5\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">worker-2</text><path d=\"M520 106 L447 126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><path d=\"M447 180 L360 222\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-phosphor)\"></path><rect x=\"545\" y=\"130\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"622.5\" y=\"146.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1500 .. 2000</text><text x=\"622.5\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">worker-3</text><path d=\"M520 106 L622 126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><path d=\"M622 180 L360 222\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-phosphor)\"></path><rect x=\"240\" y=\"226\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">partial results combined</text></svg>", "caption": "In the simplest case, the source is split until there is a piece per thread, and the partial results are combined on the way back."}
```

## Splitting is the source's job

A parallel stream splits its source with a **spliterator**, an iterator that can also cut itself in
two. How well that works depends entirely on the source:

| source | splits | why |
|---|---|---|
| `ArrayList`, arrays, `IntStream.range` | evenly and cheaply | the middle index is known at once |
| `HashSet`, `HashMap` keys | reasonably | the buckets of the table can be divided |
| `LinkedList` | badly | finding the middle means walking half the list |
| `Stream.iterate`, `Files.lines`, an `Iterator` | badly | each element depends on the one before, or the size is unknown |

`groupingByConcurrent` in the program is the collector built for this: all threads add to one
`ConcurrentHashMap` instead of building a map each and merging them. Lesson 15 explains that map;
lesson 16 explains the pool the workers came from, and why it is shared by the whole program.
