---
title: State hoisting: who owns the value
version: 1
---

**To hoist state is to move it out of a composable and up to its caller, passing the value down and
a function to change it.** The counters above each own their number, and nothing outside can read or
set it. The planner needs the opposite: the screen for a new session has a minutes picker, and the
screen, not the picker, needs to know the number, to show it, check it and eventually save it.

So the picker becomes stateless, lesson 3's shape, with one more parameter, the event:

```kotlin
// app/src/main/java/com/example/planner/ui/NewSession.kt
package com.example.planner.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.res.stringResource
import com.example.planner.R

@Composable
fun MinutesPicker(minutes: Int, onMinutesChange: (Int) -> Unit) {
    Row {
        TextButton(onClick = { onMinutesChange(minutes - 5) }, enabled = minutes > 5) {
            Text(stringResource(R.string.five_less))
        }
        Text(stringResource(R.string.minutes, minutes))
        TextButton(onClick = { onMinutesChange(minutes + 5) }) {
            Text(stringResource(R.string.five_more))
        }
    }
}

@Composable
fun NewSession() {
    var minutes by rememberSaveable { mutableIntStateOf(25) }
    Column {
        MinutesPicker(minutes, onMinutesChange = { minutes = it })
        Text(stringResource(R.string.planned, minutes))
    }
}
```

```xml
<!-- app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Planner</string>
    <string name="welcome">No courses yet. Add the first one.</string>
    <string name="add_25_minutes">Add 25 minutes</string>
    <string name="five_less">5 min less</string>
    <string name="five_more">5 min more</string>
    <string name="minutes">%1$d min</string>
    <string name="planned">Planned: %1$d min</string>
</resources>
```

`MinutesPicker` cannot change the number; it can only **ask**, by calling `onMinutesChange` with the
number it would like. `NewSession` owns the state, decides to accept the request by writing it, and
the new value comes back down on the next recomposition. Here it accepts everything; a later version
could refuse more than 240 minutes in one place, without the picker knowing. A test presses the button
twice and reads what the owner shows:

```kotlin
// app/src/test/java/com/example/planner/HoistingTest.kt
package com.example.planner

import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.example.planner.ui.NewSession
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class HoistingTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun theOwnerSeesWhatThePickerAskedFor() {
        rule.setContent { NewSession() }
        repeat(2) { rule.onNodeWithText("5 min more").performClick() }
        rule.onNodeWithText("Planned: 35 min").assertExists()
        println("the owner shows: Planned: 35 min")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*HoistingTest" 2>&1 | grep -E "owner shows|^BUILD"
    the owner shows: Planned: 35 min
BUILD SUCCESSFUL in 29s
```

**Hoist the state to the lowest composable that every reader and writer of it sits under**, and no
higher. `NewSession` is that point for the minutes: the picker writes them and the summary line reads
them. Hoisting all the way to `MainActivity` would work and would make every screen recompose when one
picker moved. When lesson 10 adds a `ViewModel`, it becomes the owner for the screen's data, and
`NewSession` itself turns stateless, passing the same `minutes` and `onMinutesChange` through.
