---
title: The back stack, printed after every tap
version: 1
---

**The back stack is a list of entries, and the screen you see is the last one.** `navigate` adds an
entry to the end; `popBackStack` removes the last; the back button pops too, which section 06 shows.
Every entry remembers its route, its arguments and the state of the screen it shows, which is why
going back finds the course screen as you left it.

`TestNavHostController`, from `navigation-testing`, is a controller a test can inspect. The test
below gives it to `PlannerNavHost`, taps through the planner the way a student would, and prints the
stack after each tap:

```kotlin
// app/src/test/java/com/example/planner/NavigationTest.kt
package com.example.planner

import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.navigation.compose.ComposeNavigator
import androidx.navigation.testing.TestNavHostController
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class NavigationTest {
    @get:Rule val rule = createComposeRule()
    private lateinit var nav: TestNavHostController

    private fun stack(after: String) = rule.runOnIdle {
        val routes = nav.currentBackStack.value.mapNotNull { it.destination.route }
        println("%-22s %s".format(after, routes.joinToString("  >  ") { it.substringAfterLast('.') }))
    }

    @Test fun toAddSessionAndBack() {
        rule.setContent {
            nav = TestNavHostController(LocalContext.current).apply {
                navigatorProvider.addNavigator(ComposeNavigator())
            }
            PlannerNavHost(nav)
        }
        stack("start")
        rule.onNodeWithText("Kotlin").performClick()
        stack("tap Kotlin")
        rule.runOnIdle { println("courseId argument: " + nav.currentBackStackEntry?.arguments?.getString("courseId")) }
        rule.onNodeWithText("Add session").performClick()
        stack("tap Add session")
        rule.onNodeWithText("Save").performClick()
        stack("tap Save")
        rule.onNodeWithText("Back").performClick()
        stack("tap Back")
    }
}
```

`addNavigator(ComposeNavigator())` is the line people forget: a test controller starts without the
navigator that knows what a `composable` destination is, and the graph cannot be built without it.
`substringAfterLast('.')` only shortens the printed routes, which Navigation names after the full
class, `com.example.planner.CourseDetail`.

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.NavigationTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 53s
ana@vm:~/planner$ grep -h -e 'start ' -e '^tap ' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.NavigationTest.xml | sed 's/.*CDATA\[//'
start                  Courses
tap Kotlin             Courses  >  CourseDetail/{courseId}
tap Add session        Courses  >  CourseDetail/{courseId}  >  AddSession/{courseId}
tap Save               Courses  >  CourseDetail/{courseId}
tap Back               Courses
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l09-stack\" aria-label=\"The back stack after each step of the test. At the start it holds Courses. Tapping Kotlin pushes CourseDetail on top. Tapping Add session pushes AddSession. Tapping Save pops it, leaving Courses and CourseDetail. Tapping Back pops CourseDetail, leaving Courses.\"><text x=\"78\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">start</text><rect x=\"14\" y=\"220\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"78\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Courses</text><line x1=\"14\" y1=\"266\" x2=\"142\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"220\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">tap Kotlin</text><rect x=\"156\" y=\"220\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Courses</text><rect x=\"156\" y=\"168\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">CourseDetail</text><line x1=\"156\" y1=\"266\" x2=\"284\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"362\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">tap Add session</text><rect x=\"298\" y=\"220\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Courses</text><rect x=\"298\" y=\"168\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">CourseDetail</text><rect x=\"298\" y=\"116\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">AddSession</text><line x1=\"298\" y1=\"266\" x2=\"426\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"504\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">tap Save</text><rect x=\"440\" y=\"220\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"504\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Courses</text><rect x=\"440\" y=\"168\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"504\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">CourseDetail</text><line x1=\"440\" y1=\"266\" x2=\"568\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"646\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">tap Back</text><rect x=\"582\" y=\"220\" width=\"128\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"646\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Courses</text><line x1=\"582\" y1=\"266\" x2=\"710\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">the outlined entry is the one on screen</text></svg>", "caption": "The five lines the test printed, as stacks: navigate pushes, popBackStack pops, and only the top entry is drawn."}
```

**Five taps, and the stack never held more than three entries.** Saving the session popped
`AddSession`, which is the right thing for a form: when it is done, the user is back where they
started it, and pressing back from the course screen does not open the finished form again. `Back`
popped `CourseDetail` and left the list, alone.

The test also proves something no screenshot would: **the arguments went where they should**. The
course screen was drawn for `kotlin`, and the form after it for the same course, because each
`navigate` passed `route.courseId` on.
