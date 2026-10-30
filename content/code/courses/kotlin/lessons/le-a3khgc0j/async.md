---
title: async and await, for a result from each
version: 1
---

`launch` is for work whose result nobody needs. **`async` starts a coroutine that produces a value,
and returns a `Deferred`**, a promise of that value; `await()` suspends until it is ready and returns
it. Two loads that do not depend on each other can then run at the same time.

`Async.kt` declares no `loadWeek` or `loadGoal` of its own: it uses the ones in `Suspend.kt`. **Every
file in `src/main/kotlin` is compiled together, in one namespace**, so a top-level function in one
file is visible in all the others, and declaring a second `loadWeek` in another file would not compile:
the compiler calls that conflicting overloads. The programs in lessons 14 to 17 share this project, so
each new file uses names of its own, or reuses what an earlier file declared.

```kotlin
// src/main/kotlin/Async.kt
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlin.time.measureTime

fun main() = runBlocking {
    val oneByOne = measureTime {
        val week = loadWeek()
        val goal = loadGoal()
        println("${week.sum()} of $goal min")
    }
    println("one after the other: ${oneByOne.inWholeMilliseconds / 100 * 100} ms or so")

    val together = measureTime {
        val week = async { loadWeek() }
        val goal = async { loadGoal() }
        println("${week.await().sum()} of ${goal.await()} min")
    }
    println("side by side: ${together.inWholeMilliseconds / 100 * 100} ms or so")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=AsyncKt
loading the week
week loaded
135 of 300 min
one after the other: 500 ms or so
loading the week
week loaded
135 of 300 min
side by side: 300 ms or so
```

`loading the week` and `week loaded` are printed by `Suspend.kt`'s `loadWeek`, once per run.
`measureTime` from the standard library times a block. The program rounds down to the hundred
milliseconds, because the exact figure moves a few milliseconds between runs and the hundreds are the
point. **One after the other, the two loads took their sum, 300 and 200; side by side, they took the
longer of the two**, because both delays were running at once. The answer is the same in both: only
the waiting overlapped.

## Start both, then await

The order of the lines matters. `async` starts the work immediately, so both loads are running before
the first `await`. Writing `async { loadWeek() }.await()` and then `async { loadGoal() }.await()` would
start the second only after the first finished, and be as slow as the sequential version with more
words. **Start everything that can run concurrently, then await the results.**

## When a load fails

If `loadWeek` throws, `await()` throws the same exception in the caller, and the other `async` is
cancelled: one failed result means the combined result cannot be built, so its sibling stops wasting
work. That is structured concurrency again, and lesson 15 shows it happening.
