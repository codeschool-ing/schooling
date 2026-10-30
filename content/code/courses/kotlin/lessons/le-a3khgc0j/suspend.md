---
title: suspend: a function that can pause
version: 1
---

A study planner on a phone loads the week from a file or a server, and loading takes time. If the
code waits for it on the thread that draws the screen, the screen freezes. The old answers were a
second thread, which is expensive, or a callback, which turns a three-step operation into three
nested blocks. **A suspending function can pause in the middle, free its thread for other work, and
resume where it stopped**, while the code reads top to bottom like ordinary code.

```kotlin
// src/main/kotlin/Suspend.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking

suspend fun loadWeek(): List<Int> {
    println("loading the week")
    delay(300)
    println("week loaded")
    return listOf(45, 30, 60)
}

suspend fun loadGoal(): Int {
    delay(200)
    return 300
}

fun main() = runBlocking {
    val week = loadWeek()
    val goal = loadGoal()
    println("${week.sum()} of $goal min")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=SuspendKt
loading the week
week loaded
135 of 300 min
```

`suspend` marks `loadWeek` as a function that may pause. `delay(300)` is the pause: it suspends the
coroutine for 300 milliseconds **without blocking the thread**, which is free to run anything else in
the meantime. When the time is up, `loadWeek` resumes on the line after `delay`, with its local
variables intact. Nothing here runs at the same time as anything else yet; the two loads ran one after
the other, and section 05 makes them overlap.

## Only from a coroutine

A suspending function can be called only from another suspending function, or from a coroutine
builder such as `runBlocking`. Calling one from plain code is refused:

```kotlin
// src/main/kotlin/NotSuspend.kt
import kotlinx.coroutines.delay

fun main() {
    delay(300)
    println("done")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=NotSuspendKt
e: file:///home/ana/kt/planner/src/main/kotlin/NotSuspend.kt:5:5 Suspend function 'suspend fun delay(timeMillis: Long): Unit' can only be called from a coroutine or another suspend function.

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':compileKotlin' (registered by plugin 'org.jetbrains.kotlin.jvm').
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > Kotlin compiler: ILLEGAL_SUSPEND_FUNCTION_CALL
       Kotlin compiler error
         Suspend function 'suspend fun delay(timeMillis: Long): Unit' can only be called from a coroutine or another suspend function.
         Location: /home/ana/kt/planner/src/main/kotlin/NotSuspend.kt:5

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

BUILD FAILED in 1s
```

Delete `NotSuspend.kt` once you have seen the message: **a file that does not compile stops the whole
project from building**, including every other program in it.

The reason is mechanical. **The compiler rewrites every `suspend` function** so that it can be stopped
at each suspension point and continued later: it gets an extra hidden parameter, a continuation,
which holds where it was and what its variables were. A plain function has no continuation to pass
in, so it cannot call one. `runBlocking` is the bridge: it starts a coroutine and blocks the current
thread until that coroutine finishes, which is right for `main` and for tests, and wrong anywhere
else, because blocking a thread is what all of this exists to avoid.

## `delay` is not `Thread.sleep`

`Thread.sleep(300)` stops the thread for 300 milliseconds, and nothing else can use it. `delay(300)`
stops only the coroutine. The difference is invisible with one coroutine, and it is the entire point
with many, which section 07 measures.
