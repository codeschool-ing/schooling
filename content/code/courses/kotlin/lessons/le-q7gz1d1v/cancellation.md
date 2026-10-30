---
title: Cancellation is cooperative
version: 1
---

`job.cancel()` does not stop a coroutine from outside. **It sets a flag, and the coroutine stops the
next time it checks**: every suspending function in `kotlinx.coroutines`, `delay` included, checks,
and throws `CancellationException` if the flag is set. The exception unwinds the coroutine like any
other, so `finally` blocks run and the coroutine can clean up.

```kotlin
// src/main/kotlin/Cancel.kt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val timer = launch {
        try {
            var elapsed = 0
            while (true) {
                delay(100)
                elapsed += 100
                println("studied $elapsed ms")
            }
        } finally {
            println("timer stopped, saving the session")
        }
    }
    delay(350)
    timer.cancelAndJoin()
    println("timer cancelled: ${timer.isCancelled}")

    val busy = launch(Dispatchers.Default) {
        val end = System.currentTimeMillis() + 300
        while (System.currentTimeMillis() < end) { }
        println("busy loop ran to the end anyway")
    }
    delay(50)
    busy.cancelAndJoin()

    val polite = launch(Dispatchers.Default) {
        val end = System.currentTimeMillis() + 300
        while (System.currentTimeMillis() < end) {
            ensureActive()
        }
        println("never printed")
    }
    delay(50)
    polite.cancelAndJoin()
    println("polite loop stopped early")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=CancelKt
e: file:///home/ana/kt/planner/src/main/kotlin/Global.kt:9:1 Conflicting overloads:
fun main(): Any
e: file:///home/ana/kt/planner/src/main/kotlin/Swallow.kt:7:1 Conflicting overloads:
fun main(): Any
e: file:///home/ana/kt/planner/src/main/kotlin/Timeout.kt:13:1 Conflicting overloads:
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit
fun main(): Unit

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':compileKotlin' (registered by plugin 'org.jetbrains.kotlin.jvm').
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > Kotlin compiler: CONFLICTING_OVERLOADS
       Kotlin compiler error
         Conflicting overloads:
         fun main(): Any
         Location: /home/ana/kt/planner/src/main/kotlin/Global.kt:9

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

BUILD FAILED in 1s
```

The timer was cancelled during its fourth `delay`, which threw, the `finally` ran, and the loop never
printed `400`. `cancelAndJoin()` is `cancel()` and then `join()`, so `main` waited for the cleanup
before printing.

**The busy loop ignored the cancellation completely.** It never suspended, so it never checked, and it
ran its full 300 milliseconds and printed its line. A coroutine doing long work without suspending
must check by hand: `ensureActive()` throws `CancellationException` if the coroutine has been
cancelled, and the polite loop stopped at the next check. `isActive`, a property, is the same
information as a `Boolean` for a loop condition.

## Cleaning up after cancellation

A `finally` block runs in a coroutine that is already cancelled, so **calling a suspending function in
it throws again at once**. Saving a session to a file with a suspending function there needs
`withContext(NonCancellable) { … }`, which runs the block as if the coroutine had not been cancelled.
Use it only for short cleanup: a block that cannot be cancelled is a block nobody can stop.
