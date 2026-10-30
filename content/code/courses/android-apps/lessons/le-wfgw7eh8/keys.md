---
title: Keys, so remembered state follows its item
version: 1
---

**In a loop, Compose identifies each call by its position, unless you give it a key.** Lesson 4
said `remember` keeps a value in the node of the composable that called it. Inside a `for`, the
nodes are matched with the calls by order: the first call of the next run gets the first node of the
last run, whatever item it is drawing now. Insert an item at the top and every node after it is
handed a different item, with the old item's remembered state still inside.

`SessionLine` remembers the label it was first drawn with, which makes the mismatch visible. The test
draws two sessions, inserts a Sunday session before them, and reads the screen, once with plain
calls and once with each call wrapped in `key`:

```kotlin
// app/src/test/java/com/example/planner/KeyTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@Composable
fun SessionLine(label: String) {
    val firstSeen by remember { mutableStateOf(label) }
    Text("$label (remembered: $firstSeen)")
}

@RunWith(RobolectricTestRunner::class)
class KeyTest {
    @get:Rule
    val rule = createComposeRule()

    private fun lines() = rule.onAllNodesWithText("remembered", substring = true)
        .fetchSemanticsNodes().map { it.config[androidx.compose.ui.semantics.SemanticsProperties.Text].joinToString() }

    @Test
    fun withoutKeys() {
        val sessions = mutableStateListOf("Mon 45 min", "Tue 50 min")
        rule.setContent { Column { for (s in sessions) SessionLine(s) } }
        rule.runOnIdle { sessions.add(0, "Sun 25 min") }
        rule.waitForIdle()
        println("without key: ${lines()}")
    }

    @Test
    fun withKeys() {
        val sessions = mutableStateListOf("Mon 45 min", "Tue 50 min")
        rule.setContent { Column { for (s in sessions) key(s) { SessionLine(s) } } }
        rule.runOnIdle { sessions.add(0, "Sun 25 min") }
        rule.waitForIdle()
        println("with key:    ${lines()}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*KeyTest" 2>&1 | grep -E "key:|^BUILD"
    without key: [Sun 25 min (remembered: Mon 45 min), Mon 45 min (remembered: Tue 50 min), Tue 50 min (remembered: Tue 50 min)]
    with key:    [Sun 25 min (remembered: Sun 25 min), Mon 45 min (remembered: Mon 45 min), Tue 50 min (remembered: Tue 50 min)]
BUILD SUCCESSFUL in 13s
```

**Without keys, every row holds the remembered value of the row that used to be in its place.**
Sunday's row has Monday's value, Monday's has Tuesday's, and Tuesday's node is a new one at the end.
The labels are right because they are arguments; what is wrong is everything the rows *remembered*,
which in a real screen is whether a row was expanded, half-typed text in it, or a running animation.
With `key(s)`, Compose matches nodes by the key instead of the position, the two old rows keep their
own nodes, and only Sunday's is new.

A key must be **stable and unique**: the same item gives the same key on every run, and no two items
share one. The planner's sessions have an `id` for exactly this, and lesson 8 passes it to
`LazyColumn`, whose `items` take a `key` for the same reason. The label is the key here only because
the test's items are strings; two sessions with the same day and minutes would collide.
