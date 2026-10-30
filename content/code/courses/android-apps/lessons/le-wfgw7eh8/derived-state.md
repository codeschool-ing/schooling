---
title: derivedStateOf, for a value that changes less than its source
version: 1
---

**`derivedStateOf` turns a value that changes often into one that changes only when its result
does.** The planner's week has a goal, 300 minutes. A banner says *Keep going* until the total
reaches it and *Goal reached* after. The banner needs only a yes or a no, but the total changes on
every session added, and a composable that reads the total runs again on every one of those changes,
to compute the same `false` thirteen times in a row.

The test builds the banner two ways side by side. One reads the minutes and compares them itself;
the other reads `reached`, a derived state that recomputes `minutes >= GOAL` whenever the minutes
change but tells its readers only when the answer is different. Both receive a lambda rather than a
value, section 02's way of reading later, so the screen that owns the minutes is counted too:

```kotlin
// app/src/test/java/com/example/planner/DerivedTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

const val GOAL = 300

@Composable
fun GoalBanner(reached: Boolean, name: String) {
    SideEffect { count(name) }
    Text(if (reached) "Goal reached" else "Keep going")
}

@Composable
fun Banners() {
    var minutes by remember { mutableIntStateOf(0) }
    SideEffect { count("Banners") }
    val reached by remember { derivedStateOf { minutes >= GOAL } }
    Column {
        BannerFromMinutes({ minutes })
        BannerFromDerived({ reached })
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@Composable
fun BannerFromMinutes(minutes: () -> Int) {
    SideEffect { count("reads the minutes") }
    GoalBanner(minutes() >= GOAL, "banner below it")
}

@Composable
fun BannerFromDerived(reached: () -> Boolean) {
    SideEffect { count("reads the derived state") }
    GoalBanner(reached(), "banner below the derived one")
}

@RunWith(RobolectricTestRunner::class)
class DerivedTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun aDerivedStateChangesLessOften() {
        rule.setContent { Banners() }
        repeat(14) {
            rule.onNodeWithText("Add").performClick()
            rule.waitForIdle()
        }
        println("after 14 clicks of 25 minutes: $runs")
    }
}
```

Fourteen clicks of 25 minutes take the total from 0 to 350, past the goal at the twelfth:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*DerivedTest" 2>&1 | grep -E "after 14|^BUILD"
    after 14 clicks of 25 minutes: {Banners=1, reads the minutes=15, banner below it=2, reads the derived state=2, banner below the derived one=2}
BUILD SUCCESSFUL in 23s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" data-fig=\"l05-derived\" aria-label=\"Two rows of marks against fourteen clicks, from 25 to 350 minutes. The row for minutes has a mark at every click. The row for the derived value reached has one mark, at the twelfth click, 300 minutes, the goal.\"><defs></defs><text x=\"156\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">minutes changed</text><line x1=\"162\" y1=\"70\" x2=\"663\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"167\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"204\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"241\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"278\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"315\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"352\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"389\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"426\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"463\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"500\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"537\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"574\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"611\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"648\" y=\"58\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"156\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reached changed</text><line x1=\"162\" y1=\"130\" x2=\"663\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"574\" y=\"118\" width=\"10\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"172\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25</text><text x=\"209\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><text x=\"246\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">75</text><text x=\"283\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><text x=\"320\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">125</text><text x=\"357\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150</text><text x=\"394\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">175</text><text x=\"431\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><text x=\"468\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">225</text><text x=\"505\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">250</text><text x=\"542\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">275</text><text x=\"579\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300</text><text x=\"616\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">325</text><text x=\"653\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">350</text><text x=\"156\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minutes after each click</text><text x=\"579\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">300: the goal</text></svg>", "caption": "Fourteen changes to the source, one change to the derived value: its readers run when the answer changes, not when the input does."}
```

**The composable that read the minutes ran 15 times; the one that read the derived state ran
twice**: once at first, once when 275 became 300 and `false` became `true`. The banners below both ran
twice, because they receive a `Boolean` and are skipped while it is unchanged. And `Banners`, which
owns the minutes but only passes lambdas down, ran once: section 02's reading later, measured.

## When it is worth it

`derivedStateOf` has a cost of its own: an extra object, and a recomputation of its block whenever a
source changes. It pays when **the result changes much less often than the input**. The classic case is lesson 8's list: the scroll position changes on every frame of a fling, and a *back to top* button needs to know only whether the first item is off screen. For a result that
changes as often as its input, `derivedStateOf` is pure overhead: a `fullName` built from a first and
last name changes whenever either does, and a plain expression is right.

`remember` around it is not optional. Without it the derived state is created anew on each run,
section 02 of lesson 4's mistake, and counts nothing.
