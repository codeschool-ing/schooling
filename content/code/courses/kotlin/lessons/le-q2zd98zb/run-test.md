---
title: runTest and virtual time
version: 1
---

A `@Test` function is an ordinary function, and an ordinary function cannot call a suspending one. A
test of lesson 14's `loadWeek` needs a coroutine to run in. **`runTest` from `kotlinx-coroutines-test`
is that coroutine**, built for tests, and it does one more thing: **`delay` inside it does not wait**.

```kotlin
// src/test/kotlin/VirtualTimeTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.hours
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest

class VirtualTimeTest {
    @Test
    fun loadWeekTakesNoRealTime() = runTest {
        assertEquals(listOf(45, 30, 60), loadWeek())
        assertEquals(300, currentTime)
    }

    @Test
    fun anHourPassesAtOnce() = runTest {
        delay(1.hours)
        assertEquals(3_600_000, currentTime)
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests VirtualTimeTest
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :compileKotlin UP-TO-DATE
> Task :compileJava NO-SOURCE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar UP-TO-DATE
> Task :processTestResources NO-SOURCE

> Task :compileTestKotlin
w: file:///home/ana/kt/planner/src/test/kotlin/VirtualTimeTest.kt:13:27 This declaration needs opt-in. Its usage should be marked with '@kotlinx.coroutines.ExperimentalCoroutinesApi' or '@OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)'
w: file:///home/ana/kt/planner/src/test/kotlin/VirtualTimeTest.kt:19:33 This declaration needs opt-in. Its usage should be marked with '@kotlinx.coroutines.ExperimentalCoroutinesApi' or '@OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)'

> Task :compileTestJava NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test

VirtualTimeTest > loadWeekTakesNoRealTime() PASSED

VirtualTimeTest > anHourPassesAtOnce() PASSED

[Incubating] Problems report is available at: file:///home/ana/kt/planner/build/reports/problems/problems-report.html

BUILD SUCCESSFUL in 2s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

An hour of `delay` passed, and the whole run took the few seconds Gradle always takes. **`runTest` keeps a
clock of its own**, `currentTime`, in milliseconds. When every coroutine in the test is waiting, it jumps
the clock to the next one due instead of sleeping. `loadWeek` delayed 300 milliseconds, so the clock
read 300; the hour read 3,600,000.

That is why a timeout, a retry with a back-off, or a reminder due tomorrow can be tested at all. Real
waiting would make a suite of them take hours; skipping the delays would test a different program.
Virtual time runs the same program, in the same order, with the waiting taken out.

The two `w:` lines are the compiler's, and they are about `currentTime`: **`kotlinx-coroutines-test`
marks part of its API experimental**, meaning its shape may still change between versions, and asks
code that uses it to say so. Answer it with an annotation on the class and its import:

```kotlin
import kotlinx.coroutines.ExperimentalCoroutinesApi

@OptIn(ExperimentalCoroutinesApi::class)
class VirtualTimeTest {
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests VirtualTimeTest
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :compileKotlin UP-TO-DATE
> Task :compileJava NO-SOURCE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :compileTestKotlin
> Task :compileTestJava NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test

VirtualTimeTest > loadWeekTakesNoRealTime() PASSED

VirtualTimeTest > anHourPassesAtOnce() PASSED

BUILD SUCCESSFUL in 3s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

The warnings stopped, and so did the `Problems report` line, which was Gradle collecting the same
warnings into a page. The tests in the next sections carry the annotation from the start.

`loadWeek` also printed its two lines. They went to the test's standard output, which Gradle keeps in
the report rather than printing, so the terminal shows the result and not the chatter.
