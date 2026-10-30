---
title: The process the system takes away
version: 1
---

**A ViewModel lives in memory, and memory is the first thing Android reclaims.** When the student
switches to another app and the phone runs short, the system kills the planner's process without
calling anything in it. When the student comes back, Android starts a new process, recreates the
activity, and hands it a `Bundle`: the small amount of state the old activity saved before it went
into the background. Everything else, every ViewModel included, is gone. Lesson 5 of
`mobile-fundamentals` describes this from the platform's side.

`SavedStateHandle` is the ViewModel's way into that `Bundle`. It is a map of keys to small values,
given to the ViewModel's constructor by the default factory, and whatever is in it when the activity
saves its state is written into the `Bundle` and read back into a new handle afterwards. That is why
`WeekViewModel` writes the draft into it on every keystroke, in `onDraftChange`, and reads it in its
first line.

## Imitating it in a test

The real thing needs a device. **Not run**: Google's documentation reproduces it on a phone or an
emulator by putting the app in the background and running `adb shell am kill com.example.planner`,
which kills a background process the way the system does, then reopening the app from recents. The
recording machine had neither.

What a test can do is take the two halves apart. Robolectric drives an activity through its
lifecycle by hand: this test saves the activity's state into a `Bundle`, destroys the activity *not*
as a configuration change, so its ViewModels are cleared, and builds a brand-new activity from the
`Bundle`. That is the sequence a killed process goes through, minus the process:

```kotlin
// app/src/test/java/com/example/planner/ProcessDeathTest.kt
package com.example.planner

import android.os.Bundle
import androidx.lifecycle.ViewModelProvider
import com.example.planner.ui.WeekViewModel
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import java.time.LocalDate

@RunWith(RobolectricTestRunner::class)
class ProcessDeathTest {
    @Test fun theDraftSurvivesAndTheListDoesNot() {
        val first = Robolectric.buildActivity(MainActivity::class.java).setup()
        val before = ViewModelProvider(first.get())[WeekViewModel::class.java]
        before.onDraftChange("45")
        before.onAdd(LocalDate.of(2026, 10, 26))
        before.onDraftChange("30")
        println("before: ${before.state.value.sessions.size} session(s), draft \"${before.state.value.draftMinutes}\"")

        val saved = Bundle()
        first.saveInstanceState(saved).pause().stop().destroy()

        val second = Robolectric.buildActivity(MainActivity::class.java).setup(saved)
        val after = ViewModelProvider(second.get())[WeekViewModel::class.java]
        println("after:  ${after.state.value.sessions.size} session(s), draft \"${after.state.value.draftMinutes}\"")
        println("same ViewModel: ${before === after}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ProcessDeathTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    (before|after|same)"
    before: 1 session(s), draft "30"
    after:  0 session(s), draft "30"
    same ViewModel: false
ProcessDeathTest > theDraftSurvivesAndTheListDoesNot PASSED
BUILD SUCCESSFUL in 14s
30 actionable tasks: 1 executed, 29 up-to-date
```

**The draft came back and the session did not.** The new activity got a new ViewModel, as it would
in a new process, and that ViewModel found `"30"` in its handle because the `Bundle` carried it. The
session was only ever in the old ViewModel's memory.

## What goes in the handle, and what does not

The `Bundle` is written into a system process and has a limit on its size: Google's documentation
warns that a large one makes the save fail with `TransactionTooLargeException`, and recommends
keeping it well under 50 kB. **So the handle holds what the student was in the middle of, and never
the data itself**: the text being typed, the tab that was open, the id of the course on screen. The
list of sessions is data, and data that has to outlive a process belongs in a database, which is
lesson 15. Until then the planner loses its sessions when its process dies, and this section is the
honest reason why.
