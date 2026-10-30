---
title: Errors in a flow: catch, onCompletion and retry
version: 1
---

A producer can fail halfway: the log file was cut short after two sessions. An exception thrown in a
flow travels down to the collector, and `collect` throws it like any suspending function would. **The
`catch` operator handles exceptions from everything above it**, and can emit a replacement value before
the flow ends:

```kotlin
// src/main/kotlin/FlowErrors.kt
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.onCompletion
import kotlinx.coroutines.flow.retry
import kotlinx.coroutines.runBlocking

private fun truncatedLog(): Flow<Int> = flow {
    emit(45)
    emit(30)
    throw IllegalStateException("log truncated")
}

private var attempts = 0

private fun flakyServer(): Flow<Int> = flow {
    attempts++
    println("  attempt $attempts")
    if (attempts < 3) throw IllegalStateException("server busy")
    emit(300)
}

fun main() = runBlocking {
    truncatedLog()
        .onCompletion { cause -> println("log finished, cause: ${cause?.message}") }
        .catch { e ->
            println("caught: ${e.message}")
            emit(-1)
        }
        .collect { println("got $it") }

    flakyServer()
        .retry(3)
        .collect { println("goal: $it") }
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FlowErrorsKt
got 45
got 30
log finished, cause: log truncated
caught: log truncated
got -1
  attempt 1
  attempt 2
  attempt 3
goal: 300
```

The first two values arrived, the producer threw, `onCompletion` saw the flow end with that cause, and
`catch` printed it and emitted `-1` in its place. **`onCompletion` runs however the flow ends**, normally,
by failure or by cancellation, which makes it the flow's `finally`; its `cause` is `null` for a normal
end.

## `catch` is upstream only

`catch` catches what happens above it in the chain, and nothing below it: an exception thrown inside
`collect`'s lambda goes past it to the caller. That is deliberate. **A catch belongs where a failure is
expected**, at the producer's side, and a bug in the code that uses the values should stay loud.

## `retry`

`retry(3)` collects the upstream again when it fails, up to three more times. The server answered on
the third attempt, and the collector never saw the two failures. Because a cold flow runs its producer
from the start on every collection, retrying is just collecting again; the lambda form, `retry(3) { e ->
e is IOException }`, retries only the failures worth retrying.
