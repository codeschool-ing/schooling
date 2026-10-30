---
title: popUpTo and launchSingleTop, for the stacks that grow wrong
version: 1
---

**`navigate` always pushes, and two situations make that wrong.** A student taps a course twice,
quickly, before the first tap's screen has appeared: two identical course screens are pushed, and
back has to be pressed twice to leave. And a flow that ends somewhere it already passed through, such
as "save and return to the list", pushes the list again on top of everything it passed on the way.

Both can be seen without touching the screen at all. This test drives the controller directly, on
the main thread where navigation must happen, and prints the stack each time:

```kotlin
// app/src/test/java/com/example/planner/BackStackTest.kt
package com.example.planner

import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.navigation.compose.ComposeNavigator
import androidx.navigation.testing.TestNavHostController
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class BackStackTest {
    @get:Rule val rule = createComposeRule()
    private lateinit var nav: TestNavHostController

    @Before fun start() {
        rule.setContent {
            nav = TestNavHostController(LocalContext.current).apply {
                navigatorProvider.addNavigator(ComposeNavigator())
            }
            PlannerNavHost(nav)
        }
    }

    private fun stack(label: String) = rule.runOnIdle {
        val routes = nav.currentBackStack.value.mapNotNull { it.destination.route }
        println("%-28s %s".format(label, routes.joinToString("  >  ") { it.substringAfterLast('.') }))
    }

    @Test fun doubleTap() {
        rule.runOnUiThread {
            nav.navigate(CourseDetail("kotlin"))
            nav.navigate(CourseDetail("kotlin"))
        }
        stack("navigate twice")
    }

    @Test fun doubleTapSingleTop() {
        rule.runOnUiThread {
            nav.navigate(CourseDetail("kotlin")) { launchSingleTop = true }
            nav.navigate(CourseDetail("kotlin")) { launchSingleTop = true }
        }
        stack("twice, launchSingleTop")
    }

    @Test fun backToTheListPlain() {
        rule.runOnUiThread {
            nav.navigate(CourseDetail("sql"))
            nav.navigate(AddSession("sql"))
            nav.navigate(Courses)
        }
        stack("navigate(Courses)")
    }

    @Test fun backToTheListPopping() {
        rule.runOnUiThread {
            nav.navigate(CourseDetail("sql"))
            nav.navigate(AddSession("sql"))
            nav.navigate(Courses) { popUpTo<Courses> { inclusive = true } }
        }
        stack("with popUpTo inclusive")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.BackStackTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 32s
ana@vm:~/planner$ grep -h 'navigate twice' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.BackStackTest.xml | sed 's/.*CDATA\[//'; grep -h 'launchSingleTop' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.BackStackTest.xml | sed 's/.*CDATA\[//'
navigate twice               Courses  >  CourseDetail/{courseId}  >  CourseDetail/{courseId}
twice, launchSingleTop       Courses  >  CourseDetail/{courseId}
```

The first line is the double tap: two `CourseDetail` entries for the same course. **`launchSingleTop
= true` says: if the destination is already on top, do not push another**, and the second line has
one. It is the right default for anything a user can tap twice, which is almost everything; the
planner's `onOpen` could pass it in every `navigate` it makes.

```
ana@vm:~/planner$ grep -h 'navigate(Courses)' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.BackStackTest.xml | sed 's/.*CDATA\[//'; grep -h 'popUpTo inclusive' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.BackStackTest.xml | sed 's/.*CDATA\[//'
navigate(Courses)            Courses  >  CourseDetail/{courseId}  >  AddSession/{courseId}  >  Courses
with popUpTo inclusive       Courses
```

The first line is "save and go to the list" written as a plain `navigate(Courses)`: four entries, two
of them `Courses`, and the form still in the middle. Back from the list would open the finished
form. **`popUpTo<Courses> { inclusive = true }` first pops everything down to `Courses`, and that
`Courses` too**, then pushes the new one, so the stack is a single `Courses`. Without `inclusive`,
the old `Courses` would stay and the new one land on top of it, two lists again.

The rule underneath both: **decide what back should do from the screen you are going to, and shape
the stack so that it does it.** `popBackStack()` in section 02 was the simplest case of that, and
`popUpTo` is the general one.
