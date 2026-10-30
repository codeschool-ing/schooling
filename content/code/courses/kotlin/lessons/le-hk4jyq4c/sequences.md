---
title: The sequence that is lazy
version: 1
---

A chain on a list is **eager**: `filter` walks the whole list and builds a new one, then `map` walks
that and builds another. A **sequence** is lazy: nothing happens until something asks for a result,
and then each item goes through every step before the next item starts. The two give the same
answer and do the work in a different order, and the order is the whole difference.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l05-lazy\" aria-label=\"The same chain, filter then map then first, over 45, 30, 60, 20. On the left, a list: filter runs on all four items and builds a list of three, map runs on all three and builds another list, then first takes 90; seven lambda calls. On the right, a sequence: 45 goes through filter, then map, and first has its answer, 90; two lambda calls, and 30, 60 and 20 are never touched.\"><defs><marker id=\"l05-lazy-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"180\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">list: eager, step by step</text><text x=\"540\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">sequence: lazy, item by item</text><rect x=\"40\" y=\"44\" width=\"280\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">filter: 45  30  60  20</text><path d=\"M180 86 L180 104\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-lazy-ah-amber)\"></path><rect x=\"40\" y=\"106\" width=\"280\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">map: 45  30  60</text><path d=\"M180 148 L180 166\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-lazy-ah-amber)\"></path><rect x=\"40\" y=\"168\" width=\"280\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">first: 90</text><text x=\"180\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">7 calls, 2 lists built</text><rect x=\"400\" y=\"44\" width=\"280\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45: filter → map → first</text><text x=\"540\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">first has its answer: 90</text><rect x=\"400\" y=\"140\" width=\"280\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30  60  20</text><text x=\"540\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">never touched</text><text x=\"540\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">2 calls, no list built</text></svg>", "caption": "The same answer, two orders of work. A list finishes each step before the next; a sequence finishes each item before the next, and stops when the answer is known."}
```

The clearest way to see the order is to make each step say when it runs:

```kotlin
// Lazy.kt
fun main() {
    val minutes = listOf(45, 30, 60, 20)

    println("list:")
    val a = minutes
        .filter { println("  filter $it"); it >= 30 }
        .map { println("  map $it"); it * 2 }
        .first()
    println("first = $a")

    println("sequence:")
    val b = minutes.asSequence()
        .filter { println("  filter $it"); it >= 30 }
        .map { println("  map $it"); it * 2 }
        .first()
    println("first = $b")
}
```

```
ana@vm:~/kt/l05$ kotlinc Lazy.kt -include-runtime -d lazy.jar && java -jar lazy.jar
list:
  filter 45
  filter 30
  filter 60
  filter 20
  map 45
  map 30
  map 60
first = 90
sequence:
  filter 45
  map 45
first = 90
```

The list filtered all four items, then mapped the three that passed, then took the first. **The
sequence filtered one item, mapped it, and stopped**, because `first()` had its answer. Two calls
against seven, and the gap grows with the list.

## Nothing happens without a terminal operation

`filter` and `map` on a sequence return another sequence and run nothing. Only a terminal operation,
one that returns something other than a sequence, makes the work happen: `first`, `toList`, `sum`,
`count`, `forEach`. A sequence chain with no terminal operation does nothing at all, and the
compiler does not warn about it.

## Sequences can be infinite

Because nothing is computed until asked, a sequence can describe more items than could exist:

```kotlin
// Infinite.kt
fun main() {
    val doubling = generateSequence(15) { it * 2 }
    println(doubling.take(5).toList())
    println(doubling.first { it > 1000 })
}
```

```
ana@vm:~/kt/l05$ kotlinc Infinite.kt -include-runtime -d infinite.jar && java -jar infinite.jar
[15, 30, 60, 120, 240]
1920
```

`generateSequence(15) { it * 2 }` is 15, 30, 60, and so on without end. `take(5)` and
`first { … }` ask for a finite part of it, and only that part is computed.

## When to use one

**A list is the default, and a sequence is for a long chain over a large collection, or a source with
no end.** For a few dozen items the list's intermediate lists cost less than the sequence's
machinery, and a list is easier to debug because each step can be printed as a whole. Lesson 16's
`Flow` is the same idea extended to values that arrive over time, and it is cold, which is lesson
16's word for lazy.
