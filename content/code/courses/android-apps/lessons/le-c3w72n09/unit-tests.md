---
title: Unit tests, and a failure worth reading
version: 1
---

**A unit test runs one piece of code with inputs you chose and compares the result with the one you
expected.** The planner's week total is the first piece worth that: it decides which sessions count
as "this week", and a mistake there is invisible on any day but the one where it matters.

Start from lesson 1's project. The build file is lesson 1's with a `testLogging` block added, so that
the test output appears as it does here:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.roborazzi)
}

android {
    namespace = "com.example.planner"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example.planner"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.testLogging {
                events("passed", "failed")
                showStandardStreams = true
            }
        }
    }
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
}
```

## The code, with a mistake in it

Here is the planner's model and its week, written the way a lot of code is first written: with a
week that starts on Sunday, because that is what the calendar on many phones shows.

```kotlin
// app/src/main/java/com/example/planner/data/Week.kt
package com.example.planner.data

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)

data class WeekTotal(val planned: Int, val done: Int, val sessions: Int)

/** Monday to Sunday of the week that contains [day]. */
fun weekOf(day: LocalDate): ClosedRange<LocalDate> {
    val start = day.with(TemporalAdjusters.previousOrSame(DayOfWeek.SUNDAY))
    return start..start.plusDays(6)
}

fun weekTotal(sessions: List<StudySession>, day: LocalDate): WeekTotal {
    val week = weekOf(day)
    val inWeek = sessions.filter { it.date in week }
    return WeekTotal(
        planned = inWeek.sumOf { it.minutes },
        done = inWeek.filter { it.done }.sumOf { it.minutes },
        sessions = inWeek.size,
    )
}
```

And the tests. They say what the planner promises: a week runs Monday to Sunday, a Sunday belongs to
the week that ends on it, and the total counts only that week's sessions. The data is the planner's
usual week, starting on Monday 26 October 2026, with one session on the Monday after:

```kotlin
// app/src/test/java/com/example/planner/data/WeekTest.kt
package com.example.planner.data

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

class WeekTest {
    private val monday = LocalDate.of(2026, 10, 26)
    private val sessions = listOf(
        StudySession(1, "kotlin", monday, 45, done = true),
        StudySession(2, "android", monday.plusDays(2), 90),
        StudySession(3, "sql", monday.plusDays(6), 25, done = true),
        StudySession(4, "kotlin", monday.plusDays(7), 50),
    )

    @Test fun aWeekRunsMondayToSunday() {
        assertEquals(monday..monday.plusDays(6), weekOf(monday.plusDays(3)))
    }

    @Test fun sundayBelongsToTheWeekThatEndsOnIt() {
        assertEquals(monday..monday.plusDays(6), weekOf(monday.plusDays(6)))
    }

    @Test fun theTotalCountsOnlyThisWeek() {
        assertEquals(WeekTotal(planned = 160, done = 70, sessions = 3), weekTotal(sessions, monday.plusDays(6)))
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD|tests completed'
> Task :app:testDebugUnitTest FAILED
WeekTest > sundayBelongsToTheWeekThatEndsOnIt FAILED
    java.lang.AssertionError at WeekTest.kt:22
WeekTest > theTotalCountsOnlyThisWeek FAILED
    java.lang.AssertionError at WeekTest.kt:26
WeekTest > aWeekRunsMondayToSunday FAILED
    java.lang.AssertionError at WeekTest.kt:18
3 tests completed, 3 failed
BUILD FAILED in 8s
ana@vm:~/planner$ grep -ho 'message="[^"]*"' app/build/test-results/testDebugUnitTest/*.xml
message="java.lang.AssertionError: expected:&lt;2026-10-26..2026-11-01&gt; but was:&lt;2026-11-01..2026-11-07&gt;"
message="java.lang.AssertionError: expected:&lt;WeekTotal(planned=160, done=70, sessions=3)&gt; but was:&lt;WeekTotal(planned=75, done=25, sessions=2)&gt;"
message="java.lang.AssertionError: expected:&lt;2026-10-26..2026-11-01&gt; but was:&lt;2026-10-25..2026-10-31&gt;"
```

**Read a failing test from its message, not from its name.** Gradle's summary says three tests failed
and on which lines; the result files hold what each one expected and what it got, and the second
command lists those messages. The Thursday test is the bug in one line: it expected
`2026-10-26..2026-11-01` and got `2026-10-25..2026-10-31`, a week that runs Sunday to Saturday. The
Sunday test is worse: asked about Sunday 1 November, the code put it at the *start* of the next week,
`2026-11-01..2026-11-07`. And the total, asked on that Sunday, counted the wrong week entirely: 75
minutes in 2 sessions, the Sunday's and the following Monday's, instead of 160 in 3.

## The fix

```kotlin
// app/src/main/java/com/example/planner/data/Week.kt
package com.example.planner.data

import java.time.DayOfWeek
import java.time.LocalDate

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)

data class WeekTotal(val planned: Int, val done: Int, val sessions: Int)

/** Monday to Sunday of the week that contains [day]. */
fun weekOf(day: LocalDate): ClosedRange<LocalDate> {
    val monday = day.with(DayOfWeek.MONDAY)
    return monday..monday.plusDays(6)
}

fun weekTotal(sessions: List<StudySession>, day: LocalDate): WeekTotal {
    val week = weekOf(day)
    val inWeek = sessions.filter { it.date in week }
    return WeekTotal(
        planned = inWeek.sumOf { it.minutes },
        done = inWeek.filter { it.done }.sumOf { it.minutes },
        sessions = inWeek.size,
    )
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD|tests completed'
WeekTest > sundayBelongsToTheWeekThatEndsOnIt PASSED
WeekTest > theTotalCountsOnlyThisWeek PASSED
WeekTest > aWeekRunsMondayToSunday PASSED
BUILD SUCCESSFUL in 3s
```

`with(DayOfWeek.MONDAY)` moves a date to the Monday of its own week, counted Monday to Sunday, and the
three tests pass. **Notice which test was cheapest to write and which one mattered most.** The first
compares the range itself, so it catches a wrong start on any day of the week. The third only caught
it because its data had a session on a Sunday: a week of sessions from Tuesday to Friday sums to the
same total either way, and would have passed both versions. The dates in a test are chosen to sit on
the edges, not typed in at random.
