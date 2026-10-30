---
title: Testing what goes wrong
version: 1
---

Lesson 17 made one decision about failure: **a missing file is a state the screen draws, and a bug is
not**. `refresh` catches `IOException` and nothing else. Both halves are behaviour, and both can be
tested, because the model is given its source rather than finding one:

```kotlin
// src/test/kotlin/FailureTest.kt
import java.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class FailureTest {
    @Test
    fun aMissingFileIsAState() = runTest {
        val model = WeekModel(this) { throw IOException("week.txt is missing") }
        model.refresh()
        advanceUntilIdle()
        assertEquals(WeekUi.Failed("week.txt is missing"), model.state.value)
    }

    @Test
    fun aBugIsNotAState() {
        val e = assertFailsWith<IllegalStateException> {
            runTest {
                WeekModel(this) { error("a bug in the source") }.refresh()
            }
        }
        assertEquals("a bug in the source", e.message)
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests FailureTest
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

FailureTest > aBugIsNotAState() PASSED

FailureTest > aMissingFileIsAState() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

The first test is the screen's sad path, with no file system involved: the source throws the exception a
missing file would, and the state says so. **The second is the one that protects the decision.**
`error(…)` throws `IllegalStateException`, which `refresh` does not catch, so the launched coroutine
fails, the failure reaches the test's scope as lesson 15 described, and `runTest` rethrows it when it
finishes. `assertFailsWith` around `runTest` turns that into a pass.

Somebody tidying up later will be tempted to write `catch (e: Exception)` in `refresh`, so that "nothing
crashes". That change would swallow cancellation and bugs alike, and this test is what fails when they
make it.

`runTest` rethrowing is also a guard in every other test. **An exception in a coroutine the test
launched fails the test**, even when the test's own assertions passed, so a failure in background work
cannot go unnoticed in a green suite.
