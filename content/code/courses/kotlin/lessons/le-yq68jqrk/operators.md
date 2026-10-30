---
title: Operators: map, filter, take and onEach
version: 1
---

A flow has the operators of lesson 5's collections, with the same names and the same lambdas. **Each
operator returns a new flow and runs nothing**; the chain describes what will happen to each value, and
`collect` at the end makes it happen, one value at a time through the whole chain.

```kotlin
// src/main/kotlin/FlowOps.kt
import kotlinx.coroutines.flow.asFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    listOf(45, 20, 60, 30, 90).asFlow()
        .onEach { println("  saw $it") }
        .filter { it >= 30 }
        .map { "$it min" }
        .take(2)
        .collect { println(it) }
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowOpsKt
  saw 45
45 min
  saw 20
  saw 60
60 min
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l16-pipeline\" aria-label=\"A flow pipeline drawn left to right: the source 45, 20, 60, 30, 90, then onEach, filter it &gt;= 30, map to text, take(2), and collect. Each value travels through every step before the next value starts. 45 reaches collect. 20 stops at filter. 60 reaches collect, take has its two values and cancels the source, so 30 and 90 are never emitted.\"><defs><marker id=\"l16-pipeline-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l16-pipeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"14\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">asFlow()</text><rect x=\"132\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"182\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">onEach</text><path d=\"M116 58 L130 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><rect x=\"250\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">filter ≥ 30</text><path d=\"M234 58 L248 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><rect x=\"368\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"418\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">map</text><path d=\"M352 58 L366 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><rect x=\"486\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"536\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">take(2)</text><path d=\"M470 58 L484 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><rect x=\"604\" y=\"40\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"654\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">collect</text><path d=\"M588 58 L602 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><text x=\"40\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">45</text><path d=\"M70 104 L654 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-phosphor)\"></path><text x=\"40\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><path d=\"M70 132 L300 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-paper-dim)\"></path><text x=\"40\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">60</text><path d=\"M70 160 L654 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-pipeline-ah-phosphor)\"></path><text x=\"40\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">30  90</text><text x=\"600\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">printed</text><text x=\"370\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">stopped by the filter</text><text x=\"600\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">second value: source cancelled</text><text x=\"250\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">never emitted</text></svg>", "caption": "One value at a time through the whole chain; take(2) cancels the source once it has its two."}
```

`asFlow()` turns a list into a flow. Follow the values: 45 went through every step and was printed; 20
was seen and stopped by the filter; 60 went through and was the second value `take(2)` wanted. **Then the
flow stopped**: 30 and 90 were never even seen. `take` cancels the producer once it has its count, using
lesson 15's cancellation, so a flow reading a large file stops reading it.

`onEach` runs a side effect and passes the value on unchanged, the flow version of lesson 6's `also`.
Placed first, it shows exactly which values the producer emitted.

## Operators run the lambdas as suspending code

The lambdas of `map`, `filter` and `onEach` on a flow may suspend: `map { loadDetails(it) }` can call a
suspending function for each value. **That is the difference from a sequence**, and it is what lets a
flow pipeline read from a file, call a server or wait between steps with no change to its shape.

`transform` is the general operator underneath most of them: its lambda receives each value and may
`emit` none, one or several values downstream. `map` is a `transform` that emits once, and `filter` one
that emits zero or one times.
