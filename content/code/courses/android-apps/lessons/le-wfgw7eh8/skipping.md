---
title: Skipping, and the arguments Compose compares
version: 1
---

**When a composable's parent runs again, Compose compares each argument with the one it got last
time, and skips the call if none changed.** That comparison is where most of the cost of
recomposition is won or lost, and **how** Compose compares an argument depends on its type's
**stability**: whether Compose can trust that an object which compared equal before is still equal.

The study session gets its own file, the same model every lesson of this course uses:

```kotlin
// app/src/main/java/com/example/planner/data/StudySession.kt
package com.example.planner.data

import java.time.LocalDate

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)
```

The test gives one screen three children, and passes them arguments in three different ways each
time the screen runs: the same list it remembered, a new list with the same contents, and a new
`Draft`, a small class with a `var` in it:

```kotlin
// app/src/test/java/com/example/planner/SkippingTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.example.planner.data.StudySession
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

val week = listOf(
    StudySession(1, "kotlin", LocalDate.of(2026, 10, 26), 45),
    StudySession(2, "sql", LocalDate.of(2026, 10, 27), 50),
)

@Composable
fun SessionCount(sessions: List<StudySession>, name: String) {
    SideEffect { count(name) }
    Text("${sessions.size} sessions")
}

class Draft(var minutes: Int)

@Composable
fun DraftMinutes(draft: Draft, name: String) {
    SideEffect { count(name) }
    Text("${draft.minutes} min planned")
}

@Composable
fun SkippingScreen() {
    var minutes by remember { mutableIntStateOf(0) }
    SideEffect { count("SkippingScreen") }
    val kept = remember { week.filter { it.minutes > 0 } }
    Column {
        Text("$minutes min")
        SessionCount(kept, "same list")
        SessionCount(week.filter { it.minutes > 0 }, "new list each time")
        DraftMinutes(Draft(25), "new draft each time")
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@RunWith(RobolectricTestRunner::class)
class SkippingTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun equalArgumentsAreSkipped() {
        rule.setContent { SkippingScreen() }
        repeat(3) {
            rule.onNodeWithText("Add").performClick()
            rule.waitForIdle()
        }
        println("after 3 clicks: $runs")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*SkippingTest" 2>&1 | grep -E "after 3|^BUILD"
    after 3 clicks: {SkippingScreen=4, same list=1, new list each time=1, new draft each time=4}
BUILD SUCCESSFUL in 27s
```

The screen ran four times; its three children did not all follow it.

- **The same list, `kept`, was skipped every time.** It is the very object passed last time.
- **The new list was skipped too**, although it is a different object on every run. Compose compared
  it with the old one by **value**, `equals`, and two lists holding equal sessions are equal.
- **The new `Draft` ran every time.** `Draft` has a `var`, so its contents can change after it was
  compared; Compose calls such a class **unstable** and compares it by **identity**, `===`. A new
  object is never identical to the old one, so the call always runs.

## Strong skipping, which changed the rule in 2024

Older guides say that a composable with an unstable parameter is never skipped at all, and for
Compose before Kotlin 2.0.20 that was true. The Compose compiler now enables **strong skipping** by
default: every composable is skippable, unstable arguments are compared by identity and stable ones
by `equals`. Section 04 shows the compiler saying so in its own report, under `featureFlags`.

What strong skipping does not change is the lesson of the `Draft`: an object rebuilt on every run
defeats skipping however small it is. The fix is to stop rebuilding it, with `remember`, or to make
the type stable, which is section 04.
