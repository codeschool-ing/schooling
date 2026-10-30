---
title: Reading a failing test
version: 1
---

A test that has never failed has not been seen to work. Here is one that fails, written with a slip
anybody makes, in a file of its own:

```kotlin
// src/test/kotlin/SummaryTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals

class SummaryTest {
    @Test
    fun threeSessions() {
        assertEquals("3 sessions, 135 mins", describe(WeekUi.Loaded(listOf(45, 30, 60))))
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew test --tests SummaryTest
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

> Task :test FAILED

SummaryTest > threeSessions() FAILED
    org.opentest4j.AssertionFailedError: expected: <3 sessions, 135 mins> but was: <3 sessions, 135 min>

1 test completed, 1 failed

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':test'.
> There were failing tests. See the report at: file:///home/ana/kt/planner/build/reports/tests/test/index.html

* Try:
> Run with --scan to get full insights from a Build Scan (powered by Develocity).

BUILD FAILED in 2s
4 actionable tasks: 2 executed, 2 up-to-date
```

Read it from the top. **The line under the test's name is the whole diagnosis**: what was expected, and
what the code produced. Everything from `FAILURE:` down is Gradle saying the `test` task failed, and the
report it names is the same information as a web page, useful when there are dozens of failures.

The two strings differ by one `s`. **The question a failure asks is which side is wrong**, and it is not
always the code. Here the code says `min`, as every capture since lesson 17 did, and the test was typed
from memory. Change the expected string to `"3 sessions, 135 min"` and run it again:

```
ana@vm:~/kt/planner$ ./gradlew test --tests SummaryTest
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

SummaryTest > threeSessions() PASSED

BUILD SUCCESSFUL in 2s
4 actionable tasks: 2 executed, 2 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

The opposite case is the one tests exist for: the expected value was right, the code changed, and the
failure is the first anybody hears of it. Either way, **a red test is fixed by deciding, not by editing
whichever side makes it green**.
