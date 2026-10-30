---
title: The system's back, and links from outside the app
version: 1
---

**On Android the back gesture belongs to the system, not to your screen**, and `NavHost` answers
it for you. The `mobile-fundamentals` course, lesson 10, compares this with iOS, where back is a
button the app draws. Here it is enough that the activity has an `OnBackPressedDispatcher`, that
`NavHost` registers with it, and that a back gesture pops the stack exactly as `popBackStack()` does.

A test can press back the way the system does, by asking the activity's dispatcher. That needs the
activity itself, so this test uses `createAndroidComposeRule<ComponentActivity>()` rather than the
plain rule, and calls the real `PlannerNavHost()` with no controller of its own:

```kotlin
// app/src/test/java/com/example/planner/SystemBackTest.kt
package com.example.planner

import androidx.activity.ComponentActivity
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class SystemBackTest {
    @get:Rule val rule = createAndroidComposeRule<ComponentActivity>()

    private fun back(label: String) {
        rule.runOnUiThread { rule.activity.onBackPressedDispatcher.onBackPressed() }
        rule.waitForIdle()
        println("%-26s finishing: %s".format(label, rule.activity.isFinishing))
    }

    @Test fun theBackButton() {
        rule.setContent { PlannerNavHost() }
        rule.onNodeWithText("Android Apps").performClick()
        rule.onNodeWithText("Add session").performClick()
        back("back from AddSession")
        rule.onNodeWithText("Add session").assertExists()
        back("back from CourseDetail")
        rule.onNodeWithText("Courses").assertExists()
        back("back from Courses")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.SystemBackTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 25s
ana@vm:~/planner$ grep -h 'finishing' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.SystemBackTest.xml | sed 's/.*CDATA\[//'
back from AddSession       finishing: false
back from CourseDetail     finishing: false
back from Courses          finishing: true
```

**Two backs popped the stack; the third finished the activity.** With only `Courses` left there is
nothing for `NavHost` to pop, so it stops answering and the dispatcher falls through to its default,
which closes the activity: the student is back at the home screen. That is the behaviour users
expect, and it came from the library rather than from code in the planner.

**Not run:** the predictive back animation. From Android 13 an app can opt in to predictive back,
which shows the screen underneath while the back gesture is still in progress. It is a gesture on a
device, and Google's documentation on predictive back describes it; nothing here could draw it.

## Deep links

A **deep link** opens a screen in the middle of the app from outside it: a reminder notification
that opens a course, or a link in an e-mail. In Navigation Compose a destination declares the
addresses it answers with `deepLinks = listOf(navDeepLink<CourseDetail>(basePath = …))`, the
manifest declares that the activity handles them, and Navigation builds the back stack the student
would have had if they had tapped their way there. The `mobile-fundamentals` course, lesson 11,
explains deep links and verified app links on both platforms; a notification, lesson 19's subject,
is the commonest way into one.

**Not run:** opening a deep link, which needs a device and `adb shell am start` with the link, as
Google's documentation on testing deep links shows.
