---
title: Two ways to break the structure
version: 1
---

Structured concurrency holds as long as two things are true: every coroutine is started in a scope
that waits for it, and cancellation is allowed to travel. Each has a common way of being broken.

## Swallowing the cancellation

Lesson 13 warned that `runCatching` catches everything. In a coroutine, everything includes
`CancellationException`:

```kotlin
// src/main/kotlin/Swallow.kt
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val job = launch {
        repeat(5) { i ->
            runCatching { delay(100) }
            println("tick $i")
        }
    }
    delay(150)
    job.cancelAndJoin()
    println("after cancel")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=SwallowKt
tick 0
tick 1
tick 2
tick 3
tick 4
after cancel
```

The job was cancelled during its second `delay`. That `delay` threw `CancellationException`,
`runCatching` caught it, and the loop carried on: **every remaining `delay` threw at once and was
caught at once**, so ticks 1 to 4 printed in a burst after the cancellation. The job did finish,
because the loop ran out, and a loop with no end would never have. The fix is to let cancellation
through: catch the specific exceptions the block can really throw, or rethrow a
`CancellationException` when you catch something broader.

## GlobalScope

`GlobalScope` is a scope that belongs to nothing and waits for nothing. A coroutine launched in it is
not a child of the code that launched it:

```kotlin
// src/main/kotlin/Global.kt
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

@OptIn(DelicateCoroutinesApi::class)
fun main() = runBlocking {
    GlobalScope.launch {
        delay(100)
        println("session saved")
    }
    println("main finished")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=GlobalKt
main finished
```

`runBlocking` did not wait for it, because it is not its child, and the program ended before the
session was saved. Nothing reported the loss. **That is the bug structured concurrency exists to
prevent**, and the library marks `GlobalScope` as a delicate API: without the `@OptIn` line the
compiler warns about it, so using it is a decision somebody wrote down. On Android, work launched this way also outlives the screen that started it and keeps
running after the student has left. Launch in the scope that owns the work, `coroutineScope`, or the
scope a framework gives you.
