---
title: Why a long list is not a long Column
version: 1
---

**A `Column` composes every child it is given, whether or not anybody will ever scroll to it.**
For a screen of six controls that is exactly right. For a year of study sessions it means building,
measuring and keeping in memory hundreds of rows to show the dozen that fit on the screen. Add a
scroll modifier and the `Column` scrolls perfectly well; it just does all the work up front.

A `LazyColumn` composes only the rows that are on the screen, and composes more as they scroll in.
That is the whole difference, and it is easy to see by counting. The test below gives each a
thousand rows, 48 dp tall each, and counts how many times a row's content runs:

```kotlin
// app/src/test/java/com/example/planner/LazinessTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(qualifiers = "w360dp-h640dp-xhdpi")
class LazinessTest {
    @get:Rule val rule = createComposeRule()

    @Test fun column() {
        var composed = 0
        rule.setContent {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                repeat(1000) { i ->
                    composed++
                    Text("Session $i", Modifier.height(48.dp))
                }
            }
        }
        rule.waitForIdle()
        println("Column: composed $composed rows of 1000")
    }

    @Test fun lazyColumn() {
        var composed = 0
        rule.setContent {
            LazyColumn {
                items(1000) { i ->
                    composed++
                    Text("Session $i", Modifier.height(48.dp))
                }
            }
        }
        rule.waitForIdle()
        println("LazyColumn: composed $composed rows of 1000")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*.LazinessTest' 2>&1 | grep -E '^BUILD|FAILED'
BUILD SUCCESSFUL in 36s
ana@vm:~/planner$ grep -h -e 'composed' app/build/test-results/testDebugUnitTest/TEST-com.example.planner.LazinessTest.xml | sed 's/.*CDATA\[//'
Column: composed 1000 rows of 1000
LazyColumn: composed 14 rows of 1000
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l08-lazy\" aria-label=\"Two lists of the same 1000 rows. On the left, a Column composes every row, 1000 of 1000, most of them far off the screen. On the right, a LazyColumn composes only the rows inside the screen, 14 of 1000; the others are outlines that do not exist yet.\"><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">Column</text><rect x=\"90\" y=\"40\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"50\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"60\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"70\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"80\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"90\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"100\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"110\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"120\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"130\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"140\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"150\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"160\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"170\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"180\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"190\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"200\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"210\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"220\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"230\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"240\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"250\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"260\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"90\" y=\"270\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><text x=\"180\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">1000 of 1000 composed</text><text x=\"180\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">every row, on screen or not</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">LazyColumn</text><rect x=\"450\" y=\"40\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"50\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"60\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"70\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"80\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"90\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"100\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"110\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"120\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"130\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"140\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"150\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"160\" width=\"180\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"170\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"180\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"190\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"200\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"210\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"220\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"230\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"240\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"250\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"260\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"450\" y=\"270\" width=\"180\" height=\"8\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"440\" y=\"96\" width=\"200\" height=\"74\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"650\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">screen</text><text x=\"540\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">14 of 1000 composed</text><text x=\"540\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">only what the screen shows</text></svg>", "caption": "The two counts the test printed, not to scale: the outlines on the right stand for rows LazyColumn never composed."}
```

**Fourteen against a thousand.** The pretend screen is 640 dp tall and each row 48 dp, so
thirteen rows and a part of the fourteenth fit; the `LazyColumn` composed exactly those. The
`Column` composed all of them before showing the first. On a phone, that difference is the time
between tapping and seeing the list, and the memory the list holds while it is open.

Two details of the test are worth noticing. `composed++` runs **inside composition**, which lesson 3
said a real composable must never do, because composition can run any number of times; in a test
that is counting exactly that, it is the point. And `items(1000) { i -> … }` is not a loop that runs
a thousand times: it tells the list there are a thousand items and gives it a function to call for
the ones it needs. **The lambda is a recipe for one row, called on demand.**

The compiler printed a warning while building these tests: `createComposeRule` is deprecated in
favour of a `v2` version that runs coroutines differently. The tests in this lesson keep the
original, which still works, and lesson 21 is where the course turns to testing itself.

`LazyRow` is the same thing sideways, and `LazyVerticalGrid` lays the items out in columns. Everything
in this lesson applies to all three.
