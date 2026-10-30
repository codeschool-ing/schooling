---
title: The composables that should not: work done while describing
version: 1
---

**A composable must do nothing except describe the screen.** No writing to a list, no saving to a
file, no network call, no incrementing a counter that something else reads. The reason is section
06's fact: the function runs as often as Compose needs it to, and you do not decide how often. Work
put in the body of a composable is repeated every time, and work that must happen once happens
several times.

This test shows the shape of the bug. `WeekTotal` shows the week's minutes, and also does something
it should not: it records, in a list, that the total was shown, which is the kind of line somebody
writes to count screen views. The test changes the minutes three times, as a user adding three
sessions would:

```kotlin
// app/src/test/java/com/example/planner/RunsTest.kt
package com.example.planner

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.createComposeRule
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

val opened = mutableListOf<String>()

@Composable
fun WeekTotal(minutes: Int) {
    opened += "week total shown"
    Text("$minutes min this week")
}

@RunWith(RobolectricTestRunner::class)
class RunsTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun aComposableRunsMoreThanOnce() {
        var minutes by mutableIntStateOf(0)
        rule.setContent { WeekTotal(minutes) }
        for (added in listOf(25, 45, 50)) {
            minutes += added
            rule.waitForIdle()
        }
        println("the screen says: $minutes min this week")
        println("the list says: $opened")
    }
}
```

`mutableIntStateOf` is a value Compose watches, lesson 4's subject; `waitForIdle` lets Compose finish
reacting before the next change. The test prints the screen's last state and the list. It needs the
build file from lesson 2, which shows a test's printed lines:

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
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*RunsTest" 2>&1 | grep -E "STANDARD_OUT|the (screen|list)|^BUILD"
RunsTest > aComposableRunsMoreThanOnce STANDARD_OUT
    the screen says: 120 min this week
    the list says: [week total shown, week total shown, week total shown, week total shown]
BUILD SUCCESSFUL in 26s
```

**One screen, four entries.** The total was right every time, 120 at the end, because describing the
screen again with new data is exactly what Compose is for. The list is wrong, because adding to it
is not describing anything: every run of the function added one more line. A real screen-view counter
written like this would count every keystroke that changed a number on that screen.

## Three rules, and where the work goes instead

Google's documentation of Compose states what a composable may assume, and each rule is a way the
line above goes wrong:

- **It may run very often**, as many as once per frame during an animation. Anything slow in the body
  makes the screen stutter.
- **It may run in any order, or not at all.** Compose may skip a composable whose inputs did not
  change, lesson 5, and does not promise that siblings run in the order they are written.
- **Its result must depend only on its inputs.** Called twice with the same parameters, it should
  describe the same screen and change nothing else.

The work does not disappear; it moves. Something that should happen **once when a screen appears**,
such as loading its data, goes in a `LaunchedEffect`, which Compose runs once and cancels when the
composable leaves; lesson 11 uses it. Something that happens **because the user did something** goes
in an event handler, `onClick`, which runs when they press and not when the screen is drawn. And
work that is not about the screen at all goes outside the composable entirely, in lesson 10's
`ViewModel`. The body of a composable is for describing, and describing has no side effects.
