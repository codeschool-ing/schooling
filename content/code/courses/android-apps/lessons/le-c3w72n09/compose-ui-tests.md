---
title: Compose UI tests: find, act, assert
version: 1
---

**A Compose UI test talks to the screen the way an accessibility service does**: it finds nodes in
the semantics tree by what they say or by a tag, acts on them, and asserts what they say afterwards.
It never reads a variable inside your composable. That is the point: if the test can find "Turn on
reminders" by its text, so can a screen reader, and lesson 3's semantics are what both rely on.

The week screen shows the total and one row per session, each with a checkbox. It takes the
sessions as a parameter and reports a tick through a lambda, so it can be tested with any week
the test likes. The total's text is a string resource:

```xml
<!-- app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Planner</string>
    <string name="welcome">No courses yet. Add the first one.</string>
    <string name="week_total">%1$d of %2$d minutes done this week</string>
</resources>
```

```kotlin
// app/src/main/java/com/example/planner/ui/WeekScreen.kt
package com.example.planner.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.example.planner.R
import com.example.planner.data.StudySession
import com.example.planner.data.weekTotal
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

@Composable
fun WeekScreen(
    sessions: List<StudySession>,
    courseNames: Map<String, String>,
    today: LocalDate,
    onToggle: (Long) -> Unit,
) {
    val total = weekTotal(sessions, today)
    Column(Modifier.padding(16.dp)) {
        Text(
            stringResource(R.string.week_total, total.done, total.planned),
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.testTag("total"),
        )
        for (s in sessions) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth().testTag("session-${s.id}"),
            ) {
                Checkbox(checked = s.done, onCheckedChange = { onToggle(s.id) })
                val day = s.date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.ENGLISH)
                Text("$day  ${courseNames[s.courseId]}  ${s.minutes} min")
            }
        }
    }
}
```

`Modifier.testTag` gives a node a name that is for tests only and never shown. The total and each row
get one, so that the test can find "the row of session 2" without depending on its wording.

## The test

```schooling-example
{"language": "kotlin", "file": "app/src/test/java/com/example/planner/ui/WeekScreenTest.kt", "parts": [{"code": "// app/src/test/java/com/example/planner/ui/WeekScreenTest.kt\npackage com.example.planner.ui\n\nimport androidx.compose.material3.MaterialTheme\nimport androidx.compose.runtime.mutableStateListOf\nimport androidx.compose.ui.test.assertIsOff\nimport androidx.compose.ui.test.assertIsOn\nimport androidx.compose.ui.test.assertTextEquals\nimport androidx.compose.ui.test.isToggleable\nimport androidx.compose.ui.test.junit4.createComposeRule\nimport androidx.compose.ui.test.onChildren\nimport androidx.compose.ui.test.onNodeWithTag\nimport androidx.compose.ui.test.performClick\nimport androidx.compose.ui.test.filter\nimport androidx.compose.ui.test.onFirst\nimport com.example.planner.data.StudySession\nimport java.time.LocalDate\nimport org.junit.Rule\nimport org.junit.Test\nimport org.junit.runner.RunWith\nimport org.robolectric.RobolectricTestRunner\n"}, {"code": "val MONDAY: LocalDate = LocalDate.of(2026, 10, 26)\nval COURSES = mapOf(\"kotlin\" to \"Kotlin\", \"android\" to \"Android Apps\", \"sql\" to \"SQL Databases\")\nfun sampleWeek() = listOf(\n    StudySession(1, \"kotlin\", MONDAY, 45, done = true),\n    StudySession(2, \"android\", MONDAY.plusDays(2), 90),\n    StudySession(3, \"sql\", MONDAY.plusDays(4), 25),\n)\n", "note": "The planner's usual week, as top-level values, so that section 05's screenshot test can draw the same one."}, {"code": "@RunWith(RobolectricTestRunner::class)\nclass WeekScreenTest {\n    @get:Rule val rule = createComposeRule()\n", "note": "`createComposeRule()` gives the test a host for composables and the finders that search it. Under Robolectric it runs on the JVM; section 06 runs the same kind of test on a device."}, {"code": "    @Test fun tickingASessionMovesTheTotal() {\n        val sessions = mutableStateListOf(*sampleWeek().toTypedArray())\n        rule.setContent {\n            MaterialTheme {\n                WeekScreen(sessions, COURSES, MONDAY) { id ->\n                    val i = sessions.indexOfFirst { it.id == id }\n                    sessions[i] = sessions[i].copy(done = !sessions[i].done)\n                }\n            }\n        }", "note": "**Arrange.** The sessions live in a `mutableStateListOf`, so a tick replaces one with a `copy` and the screen recomposes, as it would with lesson 10's `ViewModel` holding the list."}, {"code": "        rule.onNodeWithTag(\"total\").assertTextEquals(\"45 of 160 minutes done this week\")\n        val box = rule.onNodeWithTag(\"session-2\").onChildren().filter(isToggleable()).onFirst()\n        box.assertIsOff()\n        box.performClick()\n        box.assertIsOn()", "note": "**Assert, act, assert.** Find the total by its tag and check its text. Then find the toggleable child of row 2, the checkbox, check it is off, click it and check it is on."}, {"code": "        rule.onNodeWithTag(\"total\").assertTextEquals(\"135 of 160 minutes done this week\")\n    }\n}", "note": "And the total again: 90 more minutes done."}]}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekScreenTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD|tests completed'
WeekScreenTest > tickingASessionMovesTheTotal PASSED
BUILD SUCCESSFUL in 17s
```

One test, and it covers what a student does on this screen: the total reads 45 of 160 before, the
Wednesday session's box is off, a tap turns it on, and the total reads 135 of 160 after, because
90 minutes moved from planned to done. **Nothing in the test knows how `WeekScreen` stores or
computes anything**; rename a variable, split the composable in two, move the total into a
`ViewModel` as lesson 10 would, and the test still passes for as long as the screen behaves.

## The rule this course has used, and the one that replaces it

Every Compose test earlier in this course created its rule with `createComposeRule()` from
`androidx.compose.ui.test.junit4`, and so does the test above. With the Compose release this course
pins, that function is deprecated, and the compiler says so, in a warning that is easy to scroll
past because the build still succeeds:

```
ana@vm:~/planner$ ./gradlew --console=plain compileDebugUnitTestKotlin --rerun 2>&1 | grep '^w: .*WeekScreenTest'
w: file:///home/ana/planner/app/src/test/java/com/example/planner/ui/WeekScreenTest.kt:33:26 'fun createComposeRule(effectContext: CoroutineContext = ...): ComposeContentTestRule' is deprecated. Use `androidx.compose.ui.test.junit4.v2.createComposeRule` instead. The v2 APIs use StandardTestDispatcher instead of UnconfinedTestDispatcher, which aligns with standard coroutine behavior by queuing tasks rather than executing them immediately. Tests relying on immediate execution may require explicit synchronization. Please refer to the migration guide for more details.
ana@vm:~/planner$ sed -i 's/junit4.createComposeRule/junit4.v2.createComposeRule/' app/src/test/java/com/example/planner/ui/WeekScreenTest.kt
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*WeekScreenTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD|tests completed'
WeekScreenTest > tickingASessionMovesTheTotal PASSED
BUILD SUCCESSFUL in 16s
```

**The warning is the whole explanation**, and it is worth reading to the end. The old rule runs
coroutines launched by the composition on an `UnconfinedTestDispatcher`, which executes them
immediately; the `v2` rule uses a `StandardTestDispatcher`, which queues them and runs them when the
test lets time advance, as `runTest` does in the `kotlin` course's lesson 18. A test that relied on
something happening at once may then need an explicit wait, such as `rule.waitForIdle()`. This test
did not: changing the import was the whole migration, and it passed unchanged. Sections 05 and 06
use `v2` from the start.

## When a finder finds nothing

The commonest failure in a Compose test is a finder that matches no node, or more than one. Two
tools say why. `rule.onRoot().printToLog("week")` writes the whole semantics tree to the log, with
every node's text, role and tag. And `useUnmergedTree = true` on a finder looks inside nodes that
Compose has merged: a `Row` with a `Checkbox` and a `Text` can appear as one node with both texts,
and lesson 20's `AskTwiceTest` read the merged tree's text the same way.
