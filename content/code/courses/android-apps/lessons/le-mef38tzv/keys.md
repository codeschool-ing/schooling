---
title: Keys, so that state follows the item and not the position
version: 1
---

**Without a key, a `LazyColumn` knows its rows by position**: row 0, row 1, row 2. Anything a row
remembers, a scroll position inside it, a text field half typed, whether it is expanded, belongs to
"row 0". Insert a session at the top and every session moves down one place, while every
remembered value stays where it was, now attached to a different session.

To see it, the planner needs a model and a row that remembers something. The model is the planner's,
written as every lesson that needs it writes it, with a function that makes the same list of sessions every time it is called:

```kotlin
// app/src/main/java/com/example/planner/data/StudySession.kt
package com.example.planner.data

import java.time.LocalDate

data class Course(val id: String, val name: String)

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)

val courses = listOf(Course("kotlin", "Kotlin"), Course("android", "Android Apps"), Course("sql", "SQL Databases"))

fun courseName(id: String) = courses.first { it.id == id }.name

// Three sessions a day from `start`, the same list every time it is called.
fun sessionsFrom(start: LocalDate, count: Int, firstId: Long = 1): List<StudySession> =
    (0 until count).map { i ->
        StudySession(
            id = firstId + i,
            courseId = courses[i % courses.size].id,
            date = start.plusDays(i / 3L),
            minutes = listOf(25, 45, 50, 90)[i % 4],
        )
    }
```

The row shows the course and the minutes, and a tap opens a second line with the session's id and
date. Whether it is open is state the row keeps with `remember`, which lesson 4 introduced:

```kotlin
// app/src/main/java/com/example/planner/ui/SessionItem.kt
package com.example.planner.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.planner.data.StudySession
import com.example.planner.data.courseName

@Composable
fun SessionItem(session: StudySession, modifier: Modifier = Modifier) {
    var open by remember { mutableStateOf(false) }
    Column(
        modifier
            .fillMaxWidth()
            .clickable { open = !open }
            .padding(horizontal = 16.dp, vertical = 12.dp),
    ) {
        Text("${courseName(session.courseId)} · ${session.minutes} min", style = MaterialTheme.typography.titleMedium)
        if (open) {
            Text("Session ${session.id}, ${session.date}", style = MaterialTheme.typography.bodySmall)
        }
    }
}
```

The test builds a list of three sessions, opens the first, inserts a new session above it, and asks
which session's details are now showing. It does that twice, once without keys and once with
`key = { it.id }`:

```kotlin
// app/src/test/java/com/example/planner/KeysTest.kt
package com.example.planner

import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.example.planner.data.StudySession
import com.example.planner.data.sessionsFrom
import com.example.planner.ui.SessionItem
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class KeysTest {
    @get:Rule val rule = createComposeRule()
    private val monday = LocalDate.of(2026, 10, 26)

    private fun openAfterInsert(useKeys: Boolean): String {
        val sessions = mutableStateListOf(*sessionsFrom(monday, 3, firstId = 10).toTypedArray())
        rule.setContent {
            LazyColumn {
                if (useKeys) items(sessions, key = { it.id }) { SessionItem(it) }
                else items(sessions) { SessionItem(it) }
            }
        }
        rule.onNodeWithText("Kotlin · 25 min").performClick()
        rule.runOnIdle { sessions.add(0, StudySession(9, "sql", monday, 50)) }
        val open = rule.onNodeWithText("Session", substring = true).fetchSemanticsNode()
        return open.config[SemanticsProperties.Text].joinToString()
    }

    @Test fun withoutKeys() = println("without keys, the open details say: " + openAfterInsert(false))

    @Test fun withKeys() = println("with keys, the open details say: " + openAfterInsert(true))
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.KeysTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 28s
ana@vm:~/planner$ grep -h -e 'keys, the' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.KeysTest.xml | sed 's/.*CDATA\[//'
without keys, the open details say: SQL Databases · 50 min, Session 9, 2026-10-26
with keys, the open details say: Kotlin · 25 min, Session 10, 2026-10-26
```

**Without keys, the details opened on the Kotlin session now show under SQL Databases**, session 9,
which nobody tapped. The open state stayed at position 0 and session 9 moved into it. With the id as
the key, the state followed session 10 down to position 1, where it belongs.

The bug is quiet in the way the worst bugs are. Nothing crashes, the screen looks reasonable, and a
student who expanded one session sees another one expanded after the list refreshes from the
network. **Give every `items` call a key that is the item's identity**, which for the planner is the
session's `id`, never its position and never something that can change, like its title.

Two rules come with keys. They must be unique within the list, and a duplicate throws at run time.
And on Android they must be of a type that can be saved in a `Bundle`, so that the list's scroll
position can survive the process being restored, which lesson 4 explains; `Long`, `Int` and `String`
all qualify.
