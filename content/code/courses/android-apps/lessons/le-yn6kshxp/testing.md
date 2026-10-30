---
title: Testing a ViewModel with no Android at all
version: 1
---

**A ViewModel that holds no Android object can be tested as plain Kotlin**, and that is the cheapest
test this app will ever have. No Robolectric, no screen, no activity: construct it, call its
functions the way the screen would, and read `state.value`. The four below, build included, took
three seconds:

```kotlin
// app/src/test/java/com/example/planner/ui/WeekViewModelTest.kt
package com.example.planner.ui

import androidx.lifecycle.SavedStateHandle
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import java.time.LocalDate

class WeekViewModelTest {
    private val monday = LocalDate.of(2026, 10, 26)

    @Test fun aValidDraftBecomesASessionAndTheDraftEmpties() {
        val vm = WeekViewModel(SavedStateHandle())
        vm.onDraftChange("45")
        vm.onAdd(monday)
        assertEquals(45, vm.state.value.totalMinutes)
        assertEquals("", vm.state.value.draftMinutes)
    }

    @Test fun aDraftOutOfRangeAddsNothing() {
        val vm = WeekViewModel(SavedStateHandle())
        vm.onDraftChange("300")
        assertFalse(vm.state.value.canAdd)
        vm.onAdd(monday)
        assertEquals(0, vm.state.value.sessions.size)
    }

    @Test fun togglingMarksOneSessionAndTheCountFollows() {
        val vm = WeekViewModel(SavedStateHandle())
        for (m in listOf("25", "50", "90")) { vm.onDraftChange(m); vm.onAdd(monday) }
        vm.onToggleDone(2)
        assertEquals(1, vm.state.value.doneCount)
        assertEquals(165, vm.state.value.totalMinutes)
    }

    @Test fun theDraftIsReadBackFromTheHandle() {
        val vm = WeekViewModel(SavedStateHandle(mapOf("draft" to "50")))
        assertEquals("50", vm.state.value.draftMinutes)
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekViewModelTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    (before|after|same)"
WeekViewModelTest > theDraftIsReadBackFromTheHandle PASSED
WeekViewModelTest > togglingMarksOneSessionAndTheCountFollows PASSED
WeekViewModelTest > aDraftOutOfRangeAddsNothing PASSED
WeekViewModelTest > aValidDraftBecomesASessionAndTheDraftEmpties PASSED
BUILD SUCCESSFUL in 3s
30 actionable tasks: 1 executed, 29 up-to-date
```

The last test is section 05's restore in one line: a `SavedStateHandle` built from a map is what the
default factory builds from a `Bundle`. **Passing the handle in, rather than having the ViewModel
find it, is what makes that line possible**, and it is the same lesson as passing the date into
`onAdd`: whatever a class reaches for by itself, a test cannot replace.

## Which test for which question

This lesson has written three kinds, and they answer different questions:

| test | what it runs on | what it can tell you |
|---|---|---|
| `WeekViewModelTest` | the JVM, nothing else | the rules: what the state becomes after each event |
| `WeekScreenShotTest` | Robolectric and Roborazzi | the drawing: what one state looks like |
| `RecreateTest`, `ProcessDeathTest` | Robolectric, the whole activity | the wiring: that the screen, the ViewModel and the lifecycle are connected |

**Most tests belong in the first row**, because they are the fastest and they fail for one reason.
The third row is the slowest and catches what the other two cannot see, a ViewModel created per
composition, for example, or a handle nobody writes to. Lesson 21 returns to the proportions.
