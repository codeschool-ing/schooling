---
title: A Flow is a sequence that can suspend
version: 1
---

A suspending function returns one value, once. The planner has values that arrive over time: sessions
read from a log one at a time, a timer ticking, the week changing as the student studies. **A `Flow`
is a stream of values produced by suspending code**: lesson 5's sequence, with the right to `delay`
between items, and it is the type `android-apps` uses for everything a screen observes.

```kotlin
// src/main/kotlin/FlowCold.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.runBlocking

private fun sessionLog(): Flow<Int> = flow {
    println("  opening the log")
    for (minutes in listOf(45, 30, 60)) {
        delay(100)
        emit(minutes)
    }
}

fun main() = runBlocking {
    val week = sessionLog()
    println("flow created, nothing read yet")
    week.collect { println("got $it") }
    println("collecting again:")
    week.collect { println("again $it") }
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowColdKt
flow created, nothing read yet
  opening the log
got 45
got 30
got 60
collecting again:
  opening the log
again 45
again 30
again 60
```

`flow { … }` builds a flow from a block of suspending code; `emit` hands one value to whoever is
collecting. **Calling `sessionLog()` ran none of that block**: `flow created` printed before the log was
opened. The block ran when `collect` asked for values, and each value went to `collect`'s lambda as it
was emitted, a hundred milliseconds apart.

## Cold: each collector gets its own run

The second `collect` printed `opening the log` again and got the three values again. **A flow built this
way is cold: it does nothing until collected, and each collection runs the producer from the start.**
That is lesson 5's laziness, extended to time, and it is what makes a flow safe to define once and pass
around: defining it costs nothing, and nobody shares a half-read log.

The opposite, a hot stream that produces whether anybody listens or not and shares its values among
listeners, is lesson 17's `StateFlow` and `SharedFlow`.

## `collect` suspends

`collect` is a suspending function, and it returns only when the flow has finished emitting. That is
why `collecting again:` printed after the third `got`: **the code after a `collect` runs when the
stream is over**, which for a flow that never ends, a timer, is never. A screen that collects such a
flow does it in a coroutine of its own, which lesson 17 shows.
