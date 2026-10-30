---
title: A value Compose watches, and one it does not
version: 1
---

**A composable shows new data only when Compose knows the data changed.** Lesson 3 said a
composable runs again when something it reads changes. The question this section answers is what
"something" can be. An ordinary Kotlin variable is not it: Compose cannot see a `var` change. What
it can see is a **state object**, made with `mutableStateOf` or one of its siblings, and every read of
one inside a composable is recorded, so that a write can find the composables that read it.

Three counters show the difference, each a button that adds 25 minutes to a number on screen. They
live in a test file, because they are a demonstration and not part of the planner:

```kotlin
// app/src/test/java/com/example/planner/StateTest.kt
package com.example.planner

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@Composable
fun PlainCounter() {
    var minutes = 0
    Column {
        Text("$minutes min")
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@Composable
fun UnrememberedCounter() {
    var minutes by mutableIntStateOf(0)
    Column {
        Text("$minutes min")
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@Composable
fun RememberedCounter() {
    var minutes by remember { mutableIntStateOf(0) }
    Column {
        Text("$minutes min")
        Button(onClick = { minutes += 25 }) { Text("Add") }
    }
}

@RunWith(RobolectricTestRunner::class)
class StateTest {
    @get:Rule
    val rule = createComposeRule()

    private fun clickAndRead(name: String, content: @Composable () -> Unit) {
        rule.setContent(content)
        rule.onNodeWithText("Add").performClick()
        rule.waitForIdle()
        val shown = if (rule.onAllNodesWithText("25 min").fetchSemanticsNodes().isEmpty()) "0 min" else "25 min"
        println("$name after one click: $shown")
    }

    @Test fun plain() = clickAndRead("a plain var") { PlainCounter() }
    @Test fun unremembered() = clickAndRead("mutableIntStateOf without remember") { UnrememberedCounter() }
    @Test fun remembered() = clickAndRead("remember { mutableIntStateOf }") { RememberedCounter() }
}
```

`createComposeRule` comes from the `v2` package. The one in the package above it is deprecated in
this release of Compose, and the compiler's warning gives the reason: the `v2` rule queues a test's
coroutines instead of running them at once, as the rest of Kotlin's test tools do. That is why each
test here calls `waitForIdle` before reading the screen. The tests print what they see, with lesson 2's build file:

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
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*StateTest" 2>&1 | grep -E "after one click|^BUILD"
    mutableIntStateOf without remember after one click: 0 min
    a plain var after one click: 0 min
    remember { mutableIntStateOf } after one click: 25 min
BUILD SUCCESSFUL in 13s
```

The order of the three lines is the order the tests happened to run, which Gradle does not fix.
**Only one counter moved, and it needed two things.**

- **The plain `var` never shows 25.** The click changes the variable; nothing tells Compose, so
  nothing runs again and the `Text` keeps saying 0. The number in memory and the number on screen have
  parted ways, which is the worst kind of bug, because the code that changed the value looks right.
- **`mutableIntStateOf` without `remember` shows 0 too, for a different reason.** This time the
  write is seen and the composable runs again. Running again means running its first line again,
  `mutableIntStateOf(0)`, which makes a **new** state object holding 0. The 25 was written into an
  object that the new run threw away.
- **`remember` keeps the state object across runs**, and the count reaches 25.

`mutableIntStateOf` is `mutableStateOf` specialised for `Int`, so that the number is not boxed into
an object on every write; `mutableLongStateOf`, `mutableFloatStateOf` and `mutableDoubleStateOf`
exist for the same reason. Anything else uses `mutableStateOf(value)`. The `by` turns the state
object into a property, so `minutes += 25` reads and writes its `value`.
