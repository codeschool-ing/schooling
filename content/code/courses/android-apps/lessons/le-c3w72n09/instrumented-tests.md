---
title: Instrumented tests, and the run that needs a device
version: 1
---

**An instrumented test is packaged into a second APK, installed on a phone or an emulator beside the
app, and run there.** It tests the real system: the real rendering, the real dialogs, the real
`WorkManager` scheduling, everything Robolectric only imitates. The price is a device, and minutes
of installing and starting for every run.

The build needs two additions: the runner that executes the tests on the device, and the Compose
test library for the `androidTest` source set. This is the whole build file, with the two
`androidTest` lines and `testInstrumentationRunner` added:

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
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.testLogging {
                events("passed", "failed")
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

    androidTestImplementation(platform(libs.compose.bom))
    androidTestImplementation(libs.compose.ui.test.junit4)
}
```

And the test, in `app/src/androidTest`. It is the same kind of Compose test as section 04's, without
`@RunWith(RobolectricTestRunner::class)`: on a device, `AndroidJUnitRunner` runs it, and the
framework is the phone's own.

```kotlin
// app/src/androidTest/java/com/example/planner/ui/WeekScreenDeviceTest.kt
package com.example.planner.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import com.example.planner.data.StudySession
import java.time.LocalDate
import org.junit.Rule
import org.junit.Test

class WeekScreenDeviceTest {
    @get:Rule val rule = createComposeRule()

    @Test fun showsTheTotal() {
        val monday = LocalDate.of(2026, 10, 26)
        val sessions = listOf(StudySession(1, "kotlin", monday, 45, done = true))
        rule.setContent {
            MaterialTheme { WeekScreen(sessions, mapOf("kotlin" to "Kotlin"), monday) {} }
        }
        rule.onNodeWithTag("total").assertTextEquals("45 of 45 minutes done this week")
    }
}
```

## Running it here

```
ana@vm:~/planner$ ./gradlew --console=plain connectedDebugAndroidTest 2>&1 | grep -E -A2 'What went wrong|^BUILD' | grep -v '^--'
* What went wrong:
Execution failed for task ':app:connectedDebugAndroidTest' (registered by plugin 'com.android.internal.application').
> com.android.builder.testing.api.DeviceException: No connected devices!
BUILD FAILED in 2s
68 actionable tasks: 1 executed, 67 up-to-date
ana@vm:~/planner$ adb devices
List of devices attached
```

**This is the real answer from the recording machine**, and the only instrumented run in this course:
the build compiled the app and the test APK, then looked for a device and found none. `adb devices`
confirms the list is empty, for the reason lesson 1 section 02 gave.

**Not run**, therefore: the test itself. On a computer with an emulator started or a phone connected
by USB with debugging on, Google's documentation says `./gradlew connectedDebugAndroidTest` installs
both APKs, runs every test in `androidTest` on each connected device, and writes a report to
`app/build/reports/androidTests/connected/`. Android Studio runs the same tests from the gutter icon
beside each one.

## Where instrumented tests earn their cost

Keep them for what only a device can show: that the notification actually appears in the shade,
that the permission dialog returns what lesson 20 expects, that a screen scrolls smoothly on a slow
phone, that a migration of lesson 15 works on the SQLite build the phone ships. Google also offers
managed devices, emulators that Gradle starts and stops for the test run itself, and remote device
farms that run the same tests on dozens of models. Both need either a computer that can run an
emulator or an account with a service, and neither was used here.
