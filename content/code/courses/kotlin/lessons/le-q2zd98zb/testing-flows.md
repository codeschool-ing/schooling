---
title: Testing flows
version: 1
---

A cold flow that ends is the easy case: collect it into a list and compare the list. Here is a function
for the planner's running total, written in `src/main`, and a test of it:

```kotlin
// src/main/kotlin/Totals.kt
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.runningFold

fun runningTotals(sessions: Flow<Int>): Flow<Int> =
    sessions.runningFold(0) { total, m -> total + m }.drop(1)
```

A `StateFlow` never ends, so `toList()` on it would never return. The test collects it in the
background instead, into a list it can read, and stops caring when the test ends:

```kotlin
// src/test/kotlin/FlowTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class FlowTest {
    @Test
    fun totalsRunAlong() = runTest {
        assertEquals(listOf(45, 75, 135), runningTotals(flowOf(45, 30, 60)).toList())
    }

    @Test
    fun theScreenSeesEveryState() = runTest {
        val model = WeekModel(this) { listOf(45, 30) }
        val seen = mutableListOf<WeekUi>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
            model.state.toList(seen)
        }
        model.refresh()
        advanceUntilIdle()
        model.add(60)
        assertEquals(
            listOf(WeekUi.Loading, WeekUi.Loaded(listOf(45, 30)), WeekUi.Loaded(listOf(45, 30, 60))),
            seen,
        )
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests FlowTest
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :processResources NO-SOURCE
> Task :processTestResources NO-SOURCE
> Task :compileKotlin
> Task :compileJava NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar
> Task :compileTestKotlin
> Task :compileTestJava NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test

FlowTest > totalsRunAlong() PASSED

FlowTest > theScreenSeesEveryState() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 4 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

Two pieces make the second test work:

- **`backgroundScope`** is a scope `runTest` cancels when the test body ends. A collector launched in
  `this` would keep the test waiting forever for a flow with no end; one launched here is stopped for
  you.
- **`UnconfinedTestDispatcher(testScheduler)`** runs the collector the moment a value is set, rather than
  queuing it. On the queuing dispatcher of section 06, a value set and replaced before the collector's
  turn would be skipped, which is the conflation of lesson 17, and the test would be checking the
  scheduler rather than the model.

`seen` holds exactly three states, though `refresh` sets `Loading` on a state that already was
`Loading`. **The test caught a property of `StateFlow` nobody wrote down in it**: an equal value is not
emitted twice, so the screen is not asked to redraw what it already shows.

This is the shape `android-apps` uses for every screen's state holder: give it a source, collect its
state into a list, act, and compare the list.
