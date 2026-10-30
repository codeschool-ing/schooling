---
title: Timeouts
version: 1
---

A network call that never answers is a coroutine that never finishes, and a scope that waits for it
never finishes either. **`withTimeout(ms) { … }` cancels its block if it takes longer than the limit**,
using the same cooperative cancellation as `cancel()`:

```kotlin
// src/main/kotlin/Timeout.kt
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withTimeoutOrNull

private suspend fun slowServer(ms: Long): List<Int> {
    delay(ms)
    return listOf(45, 30)
}

fun main() = runBlocking {
    println(withTimeoutOrNull(500) { slowServer(200) })
    println(withTimeoutOrNull(500) { slowServer(2000) })
    try {
        withTimeout(500) { slowServer(2000) }
    } catch (e: TimeoutCancellationException) {
        println("gave up: ${e.message}")
    }
    println("planner carries on")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=TimeoutKt
[45, 30]
null
gave up: Timed out waiting for 500 ms
planner carries on
```

`withTimeoutOrNull` returns `null` when time runs out, which lesson 2's `?:` then answers: **use it when
a slow answer has a sensible replacement**, a cached week, an empty list. `withTimeout` throws
`TimeoutCancellationException` instead, for when running out of time is a failure the caller has to
know about.

## A timeout is cancellation

`TimeoutCancellationException` is a subclass of `CancellationException`, so everything the cancellation
section said holds: the block stops at its next suspension point, `finally` blocks run, and a block
that never suspends never notices the timeout. **A timeout around a busy loop with no
`ensureActive()` runs the loop to the end**, and only then reports that it was too slow.

The last line of `main` is there for a reason worth knowing. **A `main` whose last expression is not
`Unit` is not an entry point**, and in a project with several programs it then collides with every
other `main`: without that line, the `try` would be the value of `main`, of type `Any`, and the
project would stop compiling with conflicting overloads.

The catch in `main` is a narrow one, on purpose. Catching `CancellationException` itself, or anything
above it such as `Exception`, inside a coroutine, has a cost the next section shows.
