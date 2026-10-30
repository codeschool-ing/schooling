---
title: What a ViewModel outlives
version: 1
---

**Turning the phone destroys the activity and builds a new one**, and lesson 2 watched it happen:
`onDestroy`, then a fresh `onCreate` on a different object. Anything held in the activity, or in a
composable's plain `remember`, goes with the old object. Lesson 4 kept small values across that with
`rememberSaveable`. A whole screen's state, with a list in it, needs a holder that is not destroyed
at all, and that is what the ViewModel base class buys.

The mechanism is a **`ViewModelStore`**: a map from a key to a ViewModel, owned by the activity but
kept across a configuration change. When the old activity is destroyed *because* the configuration
changed, Android hands its store to the new one, and `viewModel()` finds the existing instance under
the same key instead of making a new one. When the activity is destroyed for good, the store calls
`onCleared()` on each ViewModel and empties itself.

## Watching it

This test opens the planner, types 45 into the field and presses **Add**, then recreates the
activity the way a rotation does. Before and after, it prints the identity of the activity and of the
ViewModel it finds:

```kotlin
// app/src/test/java/com/example/planner/RecreateTest.kt
package com.example.planner

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.lifecycle.ViewModelProvider
import com.example.planner.ui.WeekViewModel
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class RecreateTest {
    @get:Rule val rule = createAndroidComposeRule<MainActivity>()

    @Test fun theViewModelOutlivesTheActivity() {
        rule.onNodeWithText("Minutes").performTextInput("45")
        rule.onNodeWithText("Add").performClick()
        println("before: ${identities()}")
        rule.activityRule.scenario.recreate()
        println("after:  ${identities()}")
        rule.onNodeWithText("45 min this week, 0 of 1 done").assertExists()
    }

    private fun identities(): String {
        var text = ""
        rule.activityRule.scenario.onActivity { activity ->
            val viewModel = ViewModelProvider(activity)[WeekViewModel::class.java]
            text = "activity@%08x viewModel@%08x".format(
                System.identityHashCode(activity), System.identityHashCode(viewModel),
            )
        }
        return text
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*RecreateTest' 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    (before|after|same)"
    before: activity@0fbb03f2 viewModel@173d8810
    after:  activity@56be6485 viewModel@173d8810
RecreateTest > theViewModelOutlivesTheActivity PASSED
BUILD SUCCESSFUL in 21s
30 actionable tasks: 1 executed, 29 up-to-date
```

**Two different activities, one ViewModel.** The numbers are identity hash codes, different on every
run; what matters is which of them changed. The activity after `recreate()` is a new object, and the
ViewModel it finds is the same one, still holding the session, so the screen it composes from
scratch says 45 minutes. `ViewModelProvider(activity)[WeekViewModel::class.java]` is the long form of
what `viewModel()` does inside `WeekRoute`: the same store, the same key.

## What survives what

A ViewModel survives a configuration change. It does not survive the process, and the difference
matters because Android kills the processes of apps in the background whenever it needs memory:

| where the value lives | rotation, dark mode, a new language | the process killed in the background | the student removes the app from recents |
|---|---|---|---|
| a field of the activity, or `remember` | lost | lost | lost |
| `rememberSaveable` (lesson 4) | kept | kept | lost |
| a ViewModel | kept | **lost** | lost |
| `SavedStateHandle` in a ViewModel (section 05) | kept | kept | lost |
| a database (lesson 15) | kept | kept | kept |

The third row is the one people get wrong. **A ViewModel is not storage**; it is a holder that
happens to outlive the most common way an activity dies. Section 05 shows the process case, and what
the planner does about it.
