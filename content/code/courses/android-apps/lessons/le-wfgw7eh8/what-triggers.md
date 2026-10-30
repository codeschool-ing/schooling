---
title: What makes a composable run again
version: 1
---

**A composable runs again when a state object it read during its last run is written.** Not when
its parent runs, not when anything on screen changes: when a value it actually read has a new
value. Compose records every read of a state object, made in the body of a composable, against that
composable; a write then finds exactly the composables that read it, and only those run again. That
is **recomposition**, and lesson 3 promised to measure it.

To measure it, each composable below records that it ran, with `SideEffect`. Lesson 3 said a
composable's body must not do work, and `SideEffect` is the sanctioned exception: Compose runs its
block once after each composition of the composable that contains it has been applied, which is
exactly the count wanted.

```kotlin
// app/src/test/java/com/example/planner/RecompositionTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
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

val runs = mutableMapOf<String, Int>()

fun count(name: String) {
    runs[name] = (runs[name] ?: 0) + 1
}

@Composable
fun WeekScreen() {
    var minutes by remember { mutableIntStateOf(0) }
    SideEffect { count("WeekScreen") }
    Column {
        Title("This week")
        Total(minutes)
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@Composable
fun Title(text: String) {
    SideEffect { count("Title") }
    Text(text)
}

@Composable
fun Total(minutes: Int) {
    SideEffect { count("Total") }
    Text("$minutes min")
}

@RunWith(RobolectricTestRunner::class)
class RecompositionTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun onlyWhatReadTheValueRunsAgain() {
        rule.setContent { WeekScreen() }
        repeat(3) {
            rule.onNodeWithText("Add").performClick()
            rule.waitForIdle()
        }
        println("after 3 clicks: $runs")
    }
}
```

`WeekScreen` owns the minutes and draws three things: a title that never changes, the total, and
the button. The test presses the button three times and prints how many times each composable ran.
It uses lesson 2's build file, to see what tests print:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.roborazzi)
}

android {
    namespace = "com.example.planner"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example.planner"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.testLogging {
                showStandardStreams = true
            }
        }
    }
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*RecompositionTest" 2>&1 | grep -E "after 3|^BUILD"
    after 3 clicks: {WeekScreen=4, Title=1, Total=4}
BUILD SUCCESSFUL in 26s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 195\" role=\"img\" data-fig=\"l05-scopes\" aria-label=\"WeekScreen drawn as a box that reads minutes and ran 4 times. Inside it, three boxes: Title with the same argument, skipped and run once; Total with a new argument each time, run 4 times; and Button, which writes minutes, with an arrow up to WeekScreen.\"><defs><marker id=\"l05-scopes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"680\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WeekScreen</text><text x=\"130\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reads minutes, so it ran 4 times</text><rect x=\"40\" y=\"80\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"140.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Title(\"This week\")</text><text x=\"140.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">same argument: skipped, ran once</text><rect x=\"270\" y=\"80\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Total(minutes)</text><text x=\"370.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">new argument: ran 4 times</text><rect x=\"500\" y=\"80\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Button(onClick)</text><text x=\"590.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">writes minutes</text><line x1=\"590\" y1=\"80\" x2=\"590\" y2=\"62\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l05-scopes-ah-amber)\"></line></svg>", "caption": "Three clicks: the write runs the composable that read the value, and the calls it makes run only where the argument changed."}
```

**`Title` ran once; the two that touched the minutes ran four times**, the first composition and
three recompositions. `WeekScreen` reads `minutes` when it passes it to `Total`, so a write to
`minutes` runs `WeekScreen` again. Running `WeekScreen` again calls `Title("This week")` and
`Total(25)`, and here the second rule appears: **Compose skips a call whose arguments are equal to
last time's.** `Title` got the same string and was skipped; `Total` got a new number and ran.

## Reading later, so less runs

`WeekScreen` ran four times only because it read the minutes itself, to hand them on. Pass a
**lambda that reads them** instead, `Total(minutesProvider = { minutes })`, and the read happens
inside `Total` when it calls the lambda. Then a write to `minutes` runs `Total` alone and
`WeekScreen` stays at one. Section 05's test is built that way. It is worth doing for a value that
changes every frame, like a scroll offset; for a click it is not worth the less readable code, and
section 07 says how to tell the difference.
