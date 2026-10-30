---
title: Six callbacks in two pairs and a pair of ends
version: 1
---

**The lifecycle is three questions the system answers for each activity**: does it exist, can
anybody see it, and is it the one in front taking touches. Each callback is the moment one answer
changes. `onCreate` and `onDestroy` bracket the object's life; `onStart` and `onStop` bracket the
time it is visible; `onResume` and `onPause` bracket the time it is in front.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 225\" role=\"img\" data-fig=\"l02-states\" aria-label=\"The lifecycle as four boxes left to right: the object made by the system, CREATED, STARTED and RESUMED. onCreate, onStart and onResume move it forward. onPause and onStop move it back, and onDestroy takes it from CREATED to DESTROYED. Home stops it at CREATED.\"><defs><marker id=\"l02-states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"64\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"85.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new MainActivity()</text><text x=\"85.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">made by the system</text><rect x=\"200\" y=\"64\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"255.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CREATED</text><text x=\"255.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exists, not visible</text><rect x=\"380\" y=\"64\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">STARTED</text><text x=\"435.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">visible</text><rect x=\"560\" y=\"64\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RESUMED</text><text x=\"615.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in front, takes touches</text><line x1=\"150\" y1=\"78\" x2=\"198\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-phosphor)\"></line><text x=\"175.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">onCreate</text><line x1=\"310\" y1=\"78\" x2=\"378\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-phosphor)\"></line><text x=\"345.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">onStart</text><line x1=\"490\" y1=\"78\" x2=\"558\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-phosphor)\"></line><text x=\"525.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">onResume</text><line x1=\"560\" y1=\"102\" x2=\"492\" y2=\"102\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-amber)\"></line><text x=\"525.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onPause</text><line x1=\"380\" y1=\"102\" x2=\"312\" y2=\"102\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-amber)\"></line><text x=\"345.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onStop</text><rect x=\"200\" y=\"166\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"255\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DESTROYED</text><text x=\"255\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gone</text><line x1=\"255\" y1=\"114\" x2=\"255\" y2=\"164\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-states-ah-amber)\"></line><text x=\"264\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onDestroy</text><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">forward, as the activity comes into view</text><text x=\"400\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">back, as it leaves; Home stops at CREATED</text></svg>", "caption": "Each callback is the moment one answer changes: the outer pair brackets the object’s life, the middle pair visibility, the inner pair being in front."}
```

The common wrong picture is that the callbacks run once each, top to bottom, like a recipe. They do
not. Between `onCreate` and `onDestroy` the middle pairs run as often as the user leaves and comes
back, and an activity spends most of its life going round the inner loops.

## Watching it without a phone

On a phone, `adb logcat -s Lifecycle` shows those log lines as they happen. **Not run**: the
recording machine had no device. A test can drive the same transitions on your computer.
`ActivityScenario`, from `androidx.test:core`, launches an activity under Robolectric and moves it
between states on command, the way the system would:

```kotlin
// app/src/test/java/com/example/planner/LifecycleTest.kt
package com.example.planner

import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ActivityScenario
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.shadows.ShadowLog

@RunWith(RobolectricTestRunner::class)
class LifecycleTest {
    @Before
    fun logToConsole() {
        ShadowLog.stream = System.out
    }

    @Test
    fun homeAndBack() {
        val scenario = ActivityScenario.launch(MainActivity::class.java)
        println("-- the user presses Home")
        scenario.moveToState(Lifecycle.State.CREATED)
        println("-- the user comes back")
        scenario.moveToState(Lifecycle.State.RESUMED)
        println("-- the user presses Back")
        scenario.close()
    }

    @Test
    fun rotation() {
        val scenario = ActivityScenario.launch(MainActivity::class.java)
        println("-- the user turns the phone")
        scenario.recreate()
    }
}
```

`ShadowLog.stream = System.out` sends what `Log.d` writes to the test's standard output, and Gradle
shows a test's standard output only when asked. The module's build file asks, in `testOptions`; this
is lesson 1's file with those four lines added:

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

The test prints a great deal besides the planner's lines: Robolectric's own log and the test
library's. The `grep` keeps the line naming each test and the lines tagged `Lifecycle`:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --rerun --tests "*LifecycleTest.homeAndBack" 2>&1 | grep -E "STANDARD_OUT|Lifecycle:|  --|^BUILD"
LifecycleTest > homeAndBack STANDARD_OUT
    D/Lifecycle: onCreate: instance 1 in this process, saved state: false
    D/Lifecycle: onStart
    D/Lifecycle: onResume
    -- the user presses Home
    D/Lifecycle: onPause
    D/Lifecycle: onStop
    -- the user comes back
    D/Lifecycle: onStart
    D/Lifecycle: onResume
    -- the user presses Back
    D/Lifecycle: onPause
    D/Lifecycle: onStop
    D/Lifecycle: onDestroy: finishing true, configuration change false
BUILD SUCCESSFUL in 18s
```

**Home is not the end of anything.** Pressing it pauses and stops the activity, and the object
stays. On a device the system also calls `onSaveInstanceState` at this point, after `onStop`,
because it may need the memory later and kill the process; Google's documentation says so for every
Android since 9. `moveToState` does not simulate that call, which is why it is missing above; the
rotation in section 04 shows it. Coming back runs
`onStart` and `onResume` on the same instance, and `onCreate` is not called again. Back is different:
it **finishes** the activity, and `onDestroy` says `finishing true`. The user has said they are
done with this screen, and the object goes.

That difference, Home keeps and Back finishes, has one exception worth knowing: from Android 12 a
launcher activity is not finished by Back but moved to the background, as if Home had been
pressed, according to Google's documentation of the activity lifecycle. `ActivityScenario.close()`
finishes the activity whatever the version, which is what the test above shows. **Not run** on a
device.
