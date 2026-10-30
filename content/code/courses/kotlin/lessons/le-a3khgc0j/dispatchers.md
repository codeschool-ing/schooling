---
title: Dispatchers: which threads a coroutine runs on
version: 1
---

A coroutine is not a thread. It runs on one, and a **dispatcher** decides which. The coroutines so far
all ran on `main`'s own thread, because `runBlocking` uses the thread that called it. The library has
three dispatchers for the rest:

| dispatcher | its threads | for |
|---|---|---|
| `Dispatchers.Default` | as many as the processor has cores | work that keeps the processor busy: sorting, parsing, computing |
| `Dispatchers.IO` | a larger pool, 64 by default | work that waits: files, network, a database |
| `Dispatchers.Main` | the one thread that draws the screen | only on Android, Swing or JavaFX; it does not exist in a plain JVM program |

**`withContext(dispatcher) { … }` runs a block on another dispatcher and returns its result**, so a
function can move its own heavy work off the caller's thread:

```kotlin
// src/main/kotlin/Dispatch.kt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.io.File

fun where() = Thread.currentThread().name.substringBefore(" @")

suspend fun readWeek(path: String): List<Int> = withContext(Dispatchers.IO) {
    println("reading on ${where()}")
    File(path).readLines().map { it.trim().toInt() }
}

suspend fun summarise(minutes: List<Int>): String = withContext(Dispatchers.Default) {
    println("summing on ${where()}")
    "${minutes.size} sessions, ${minutes.sum()} min"
}

fun main() = runBlocking {
    File("week.txt").writeText("45\n30\n60\n")
    println("main on ${where()}")
    val week = readWeek("week.txt")
    println(summarise(week))
    println("back on ${where()}")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=DispatchKt
main on main
reading on DefaultDispatcher-worker-1
summing on DefaultDispatcher-worker-1
3 sessions, 135 min
back on main
```

`main` ran on the thread called `main`, the file was read on a worker of the IO pool, the sum ran on a
worker of the Default pool, and after each `withContext` the code was **back on `main`'s thread**,
because `withContext` returns to the dispatcher it was called from. The worker numbers depend on which
thread was free, and yours may differ.

## Why this matters on Android

On Android, `Dispatchers.Main` is the thread that draws the screen and handles touches, and anything
slow on it freezes the app; past five seconds the system offers to close it. The pattern
`android-apps` uses everywhere is this one: **a screen calls a suspending function from `Main`, and
the function moves its own file, network or database work to `IO` with `withContext`**, so the caller
never has to know.

The IO and Default dispatchers share threads underneath, which is why a worker's name says
`DefaultDispatcher` even when it is doing IO work: the pools are two limits on one set of threads, not
two separate sets.
