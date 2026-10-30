---
title: What fits in a Bundle, and a Saver for what does not
version: 1
---

**`rememberSaveable` can save only what a `Bundle` can hold**: numbers, strings, booleans, arrays and
lists of those, and objects that implement `Parcelable` or `Serializable`. A planner draft, the
course and minutes somebody is halfway through entering, is a data class, and a data class is none of
those. Compose does not find out until it tries to save it.

A test can make it try. `StateRestorationTester`, from the Compose test library, runs a composable,
saves its state the way an activity would before being destroyed, and restores it into a fresh
composition, with no activity at all:

```kotlin
// app/src/test/java/com/example/planner/SaverTest.kt
package com.example.planner

import androidx.compose.material3.Text
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.test.junit4.StateRestorationTester
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

data class Draft(val courseId: String, val minutes: Int)

@RunWith(RobolectricTestRunner::class)
class SaverTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun aDraftSurvivesASaveAndRestore() {
        val tester = StateRestorationTester(rule)
        tester.setContent {
            val draft = rememberSaveable { mutableStateOf(Draft("kotlin", 45)) }
            Text(draft.value.toString())
        }
        tester.emulateSavedInstanceStateRestore()
        rule.onNodeWithText("Draft(courseId=kotlin, minutes=45)").assertExists()
    }
}
```

The test fails, and the message is in the test's report:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*SaverTest" 2>&1 | grep -E "FAILED|Exception|tests completed|^BUILD"
SaverTest > aDraftSurvivesASaveAndRestore FAILED
    java.lang.IllegalArgumentException at SaverTest.kt:25
> Task :app:testDebugUnitTest FAILED
BUILD FAILED in 25s
ana@vm:~/planner$ grep -o "message=\"[^\"]*\"" app/build/test-results/testDebugUnitTest/TEST-com.example.planner.SaverTest.xml
message="java.lang.IllegalArgumentException: MutableState containing Draft(courseId=kotlin, minutes=45) cannot be saved using the current SaveableStateRegistry. The default implementation only supports types which can be stored inside the Bundle. Please consider implementing a custom Saver for this class and pass it as a stateSaver parameter to rememberSaveable()."
```

**The message is exact: the type cannot go in a `Bundle`, and the cure is a `Saver`.** A `Saver` is
two functions: one turns the value into something a `Bundle` holds, the other turns that back into
the value. `listSaver` builds one from a list, which is the shortest way for a small class:

```kotlin
// app/src/test/java/com/example/planner/SaverTest.kt
package com.example.planner

import androidx.compose.material3.Text
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.test.junit4.StateRestorationTester
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

data class Draft(val courseId: String, val minutes: Int)

val DraftSaver = listSaver<Draft, Any>(
    save = { listOf(it.courseId, it.minutes) },
    restore = { Draft(it[0] as String, it[1] as Int) },
)

@RunWith(RobolectricTestRunner::class)
class SaverTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun aDraftSurvivesASaveAndRestore() {
        val tester = StateRestorationTester(rule)
        tester.setContent {
            val draft = rememberSaveable(saver = DraftSaver) { Draft("kotlin", 45) }
            Text(draft.toString())
        }
        tester.emulateSavedInstanceStateRestore()
        rule.onNodeWithText("Draft(courseId=kotlin, minutes=45)").assertExists()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*SaverTest" 2>&1 | grep -E "FAILED|tests completed|^BUILD"
BUILD SUCCESSFUL in 39s
```

`save` returns a list of a `String` and an `Int`, both of which a `Bundle` holds; `restore` gets that
list back and rebuilds the draft. `mapSaver` does the same with named entries, which reads better past
two or three fields. The draft is now held directly rather than inside a `mutableStateOf`, because the
test only reads it; a draft the screen edits would be `rememberSaveable(stateSaver = DraftSaver) {
mutableStateOf(…) }`, the parameter the error message named.

## The other two ways, and a size to stay under

**`@Parcelize`** generates a `Parcelable` implementation for a data class, and then `rememberSaveable`
takes it with no `Saver` at all. It needs the `kotlin-parcelize` Gradle plugin, which this course's
catalogue does not carry; Google's documentation shows it, and it was not run here.

**Keep it small whichever way.** Lesson 2 section 05 gave Google's figure: saved state under 50 kB,
because the `Bundle` crosses between processes. A draft of two fields is a few bytes. A list of every
session the student ever entered is not a draft, and belongs in lesson 15's database.
