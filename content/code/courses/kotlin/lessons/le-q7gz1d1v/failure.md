---
title: When a child fails, its siblings are cancelled
version: 1
---

The planner refreshes three things at once when it opens: it syncs reminders, reads the calendar,
and exports the week. If reading the calendar fails, **what should happen to the other two?** In
structured concurrency the answer is fixed: the failed child's exception travels up to the scope, the
scope cancels every other child, and once they have all finished, the scope throws the exception to
its caller.

```kotlin
// src/main/kotlin/Failure.kt
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    try {
        coroutineScope {
            launch {
                try {
                    delay(500)
                    println("reminders synced")
                } finally {
                    println("reminder sync cancelled")
                }
            }
            launch {
                delay(200)
                throw IllegalStateException("calendar unreachable")
            }
            launch {
                try {
                    delay(1000)
                    println("week exported")
                } finally {
                    println("export cancelled")
                }
            }
        }
    } catch (e: IllegalStateException) {
        println("refresh failed: ${e.message}")
    }
    println("planner still running")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=FailureKt
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

At 200 milliseconds the calendar child threw. The scope cancelled the other two, whose `finally`
blocks ran, and only then did `coroutineScope` rethrow `calendar unreachable` to `main`, which caught it
like an exception from any function call. **Neither sibling finished its work, and neither was
forgotten**: the refresh as a whole failed, and the code that asked for it was told.

## Why cancel the siblings

Because the result they were contributing to cannot be built any more. The three refreshes are one
operation, "open the planner", and once part of it has failed, the rest is wasted work at best and, at
worst, writes half a refresh to disk. Lesson 14's `async` pair behaved the same way: if one load
throws, the other is cancelled and `await` rethrows.

When the parts really are independent, so that one failing should leave the others alone, the scope
has to say so, and that is the next section.
