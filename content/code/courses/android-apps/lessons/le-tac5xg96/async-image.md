---
title: AsyncImage, and everything it does for one picture
version: 1
---

**Showing a picture from the network is six jobs, and `AsyncImage` does all of them.** Download the
bytes off the main thread. Decode them into a bitmap at the size the screen needs, not the size the
file has. Keep the bitmap in memory for the next time, and the bytes on disk for the time after
that. Show something while it loads and something else if it fails. And cancel the whole thing if
the composable leaves the screen first. Coil is the library that does these jobs for Compose, and
**Coil 3**, the version this course uses, is written in Kotlin with coroutines throughout.

The planner gets a picture per course: a cover at the top of each course's card. Coil arrives as
two libraries, the Compose integration and a network fetcher built on the OkHttp of lesson 13. The
build file also brings in what the tests of this lesson need, `coil-test` and Roborazzi among them:

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
    implementation(libs.coil.compose)
    implementation(libs.coil.network)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(libs.okhttp.mockwebserver)
    testImplementation(libs.coil.test)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
}
```

An image from the network needs the `INTERNET` permission, which lesson 13 added and which this
lesson's manifest declares again, since each lesson starts from lesson 1's:

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:name=".PlannerApp"
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

`android:name=".PlannerApp"` names the application class of section 04, where the image loader is
configured once for the whole app.

## The card

```kotlin
// app/src/main/java/com/example/planner/ui/CourseCard.kt
package com.example.planner.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.painter.ColorPainter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage

@Composable
fun CourseCard(name: String, coverUrl: String?, modifier: Modifier = Modifier) {
    Card(modifier.fillMaxWidth()) {
        Column {
            AsyncImage(
                model = coverUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                placeholder = ColorPainter(Color(0xFFE0E0E0)),
                error = ColorPainter(Color(0xFFB00020)),
                fallback = ColorPainter(Color(0xFF9E9E9E)),
                modifier = Modifier.fillMaxWidth().height(120.dp),
            )
            Text(name, style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(16.dp))
        }
    }
}
```

**`model` is the URL; everything else is about what the user sees.** `contentScale = Crop` fills the
120 dp strip and cuts what overflows, which suits a cover. The three painters are what shows while
the image loads, when it fails, and when `coverUrl` is `null`; section 05 draws all three. The cover
is decoration, since the course name is written under it, so `contentDescription = null` tells a
screen reader to skip it; a picture that carried information would describe it there instead.

**What `AsyncImage` does not show you is the size it asked for.** It measured the 120 dp strip and
requested the image at that size, in pixels. Section 03 is why that one decision matters more than
everything else on this page.
