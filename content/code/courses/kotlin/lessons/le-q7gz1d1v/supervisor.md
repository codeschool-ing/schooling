---
title: supervisorScope, for children that fail alone
version: 1
---

Some work is a set of independent jobs: three notifications to send, five files to upload. One
failing says nothing about the others. **`supervisorScope` is a scope in which a child's failure does
not cancel its siblings or the scope**; each child succeeds or fails on its own, and the scope still
waits for all of them.

```kotlin
// src/main/kotlin/Supervisor.kt
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.supervisorScope

fun main() = runBlocking {
    val report = CoroutineExceptionHandler { _, e -> println("a task failed: ${e.message}") }
    supervisorScope {
        launch(report) {
            delay(100)
            println("reminders synced")
        }
        launch(report) {
            delay(50)
            throw IllegalStateException("calendar unreachable")
        }
        launch(report) {
            delay(150)
            println("week exported")
        }
    }
    println("all three tasks settled")
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=SupervisorKt
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

The calendar task failed at 50 milliseconds and the other two finished as if nothing had happened.
**In a supervisor scope, each child must deal with its own failure**, because the scope does not
propagate it: `CoroutineExceptionHandler` is a last-resort handler for an exception from a `launch`
that nobody else caught, and here it reports the failure instead of letting it vanish or crash the
program.

## Which one to use

**`coroutineScope` when the children are parts of one result; `supervisorScope` when they are separate
jobs that happen to run at the same time.** Loading the week and the goal to draw one screen is the
first: without either, there is no screen. Sending a reminder to each of three devices is the second.

On Android, the scope that runs a screen's work, `viewModelScope` in `android-apps`, is a supervisor
scope for this reason: one failed request on a screen should not cancel every other thing that screen
is doing.
