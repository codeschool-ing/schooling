---
title: launch, and coroutines that run side by side
version: 1
---

`runBlocking` starts one coroutine. **`launch` starts another one inside it, and returns at once**,
without waiting for the new coroutine to finish. Two coroutines then take turns on the same thread,
each running until it suspends.

```kotlin
// src/main/kotlin/Launch.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val reminder = launch {
        repeat(3) { i ->
            println("reminder ${i + 1}: study Kotlin")
            delay(100)
        }
    }
    println("planner open")
    delay(150)
    println("still in main, reminder active: ${reminder.isActive}")
    reminder.join()
    println("reminder finished: ${reminder.isCompleted}")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=LaunchKt
planner open
reminder 1: study Kotlin
reminder 2: study Kotlin
still in main, reminder active: true
reminder 3: study Kotlin
reminder finished: true
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l14-interleave\" aria-label=\"A timeline from 0 to 300 milliseconds with two rows sharing one thread. The main coroutine prints planner open at 0, suspends in delay(150), prints still in main at 150, then waits in join. The reminder coroutine prints reminder 1 at 0, reminder 2 at 100 and reminder 3 at 200, suspending in delay(100) between them. Whenever one is suspended, the thread runs the other.\"><defs><marker id=\"l14-interleave-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"60\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">main</text><text x=\"60\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">reminder</text><path d=\"M120 190 L680 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"120.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 ms</text><text x=\"306.66666666666663\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100 ms</text><text x=\"400.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150 ms</text><text x=\"493.3333333333333\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200 ms</text><text x=\"680.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300 ms</text><rect x=\"120.0\" y=\"55\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"400.0\" y=\"55\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"444.0\" y=\"62\" width=\"236.0\" height=\"16\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"562.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">join()</text><rect x=\"164.0\" y=\"62\" width=\"232.0\" height=\"16\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"280.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">delay(150)</text><rect x=\"120.0\" y=\"125\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"306.66666666666663\" y=\"125\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"493.3333333333333\" y=\"125\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"164.0\" y=\"132\" width=\"138.66666666666663\" height=\"16\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"233.33333333333331\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">delay(100)</text><rect x=\"350.66666666666663\" y=\"132\" width=\"138.66666666666663\" height=\"16\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"420.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">delay(100)</text><text x=\"400\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper)\">one thread: whoever is not suspended runs</text></svg>", "caption": "Two coroutines on one thread: each runs until it suspends at a delay, and the other takes the thread."}
```

Read the output against the code. `launch` returned before its block had printed anything, so
`planner open` came first. Then `main` suspended at `delay(150)`, the reminder ran until its own
`delay`, `main`'s delay ended between the reminder's second and third lines, and **at every
`delay` the thread went to whichever coroutine was ready**. No second thread was involved: the
interleaving is the suspension points taking turns.

## The `Job`

`launch` returns a `Job`, a handle on the coroutine it started. `isActive` and `isCompleted` say where
it is; **`join()` suspends until it finishes**, which is how `main` waited for the third reminder
before printing its last line. `cancel()` stops it, and lesson 15 is about what happens then.

## `runBlocking` waits for its children

Remove the `join()`, and the last line prints before the third reminder, but the program still
prints the third reminder before it ends. **`runBlocking` does not return until every coroutine
launched inside it has finished.** That rule, that a coroutine waits for the coroutines it started,
is structured concurrency, and lesson 15 is built on it.
