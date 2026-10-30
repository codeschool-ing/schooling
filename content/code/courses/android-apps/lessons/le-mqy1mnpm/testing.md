---
title: Replacing a binding in a test
version: 1
---

**The reason to put the store and the clock in modules is to take them out again in a test.** A
Hilt test runs the real activity, the real screen and the real ViewModel, with a graph in which you
have swapped the parts you want to control. Here the store comes pre-filled with two sessions, and
the clock is stopped at noon on Wednesday 28 October 2026:

```kotlin
// app/src/test/java/com/example/planner/WeekHiltTest.kt
package com.example.planner

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import com.example.planner.data.InMemorySessionStore
import com.example.planner.data.SessionStore
import com.example.planner.data.StudySession
import com.example.planner.di.ClockModule
import com.example.planner.di.StoreModule
import dagger.hilt.android.testing.BindValue
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import dagger.hilt.android.testing.HiltTestApplication
import dagger.hilt.android.testing.UninstallModules
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@HiltAndroidTest
@UninstallModules(StoreModule::class, ClockModule::class)
@RunWith(RobolectricTestRunner::class)
@Config(application = HiltTestApplication::class)
class WeekHiltTest {
    @get:Rule(order = 0) val hilt = HiltAndroidRule(this)
    @get:Rule(order = 1) val compose = createAndroidComposeRule<MainActivity>()

    @BindValue @JvmField
    val store: SessionStore = InMemorySessionStore().apply {
        runBlocking {
            add(StudySession(101, "kotlin", LocalDate.of(2026, 10, 26), 50, done = true))
            add(StudySession(102, "sql", LocalDate.of(2026, 10, 27), 90))
        }
    }

    @BindValue @JvmField
    val clock: Clock = Clock.fixed(Instant.parse("2026-10-28T15:00:00Z"), ZoneId.of("America/Sao_Paulo"))

    @Test fun theScreenUsesTheStoreAndTheClockItWasGiven() {
        compose.onNodeWithText("140 min this week, 1 of 2 done").assertExists()
        compose.onNodeWithText("Minutes").performTextInput("25")
        compose.onNodeWithText("Add").performClick()
        compose.onNodeWithText("2026-10-28 · 25 min").assertExists()
        compose.onNodeWithText("165 min this week, 1 of 3 done").assertExists()
        println("sessions in the store: ${runBlocking { store.sessions().first().map { it.minutes } }}")
    }
}
```

Each annotation has one job:

| | what it does |
|---|---|
| `@HiltAndroidTest` | Hilt generates a graph for this test class alone |
| `@UninstallModules(StoreModule::class, ClockModule::class)` | removes the app's answers for the store and the clock from that graph |
| `@BindValue` | puts this field into the graph as the answer for its declared type |
| `@Config(application = HiltTestApplication::class)` | Robolectric starts Hilt's test application instead of `PlannerApp` |
| `Rule(order = 0)` on `HiltAndroidRule` | builds the graph before the compose rule starts the activity that needs it |

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-z]"
    sessions in the store: [50, 90, 25]
WeekHiltTest > theScreenUsesTheStoreAndTheClockItWasGiven PASSED
BUILD SUCCESSFUL in 35s
40 actionable tasks: 16 executed, 24 up-to-date
```

**The screen showed sessions the app never added and a date the computer did not have.** The
ViewModel was the real one, built by Hilt, and it received the fake store and the stopped clock
without a line of it changing: 50 and 90 minutes already in the week, then 25 dated the 28th, because
that is what the clock said. That is the whole case for injection in one test. Lesson 16 uses the
same move to replace a network with a fake one.

**Not run**: Hilt's instrumented tests, the same file under `androidTest` with a custom test runner
that starts `HiltTestApplication` on a device, as Google's Hilt testing guide describes. They need a
device or an emulator; section 07's version runs the identical graph on Robolectric.
