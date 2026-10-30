---
title: Channels, and the switch that belongs to the student
version: 1
---

**A channel is a category of notification that the student can turn up, down or off on its own.**
Since Android 8.0, which is API 26 and this project's `minSdk`, a notification that names no
existing channel is not shown. The point of the rule is control: a student who wants study
reminders and does not want a weekly summary switches off one channel and keeps the other, rather
than silencing the whole app.

So the planner's channels are worth designing as the student will see them, in the app's
notification settings: a name, a sentence of description, and a separate channel for each kind of
notification someone might want to treat differently. The planner has one kind today.

Start from lesson 1's project. The build file is lesson 1's with one block added, `testLogging`,
which prints what each test writes so that you see the lines this lesson shows; notifications need
no new library, because `androidx.core`, already there, carries the compatible versions of every
class used here:

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

The strings, all of this lesson's at once:

```xml
<!-- app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Planner</string>
    <string name="welcome">No courses yet. Add the first one.</string>
    <string name="channel_reminders">Study reminders</string>
    <string name="channel_reminders_description">A nudge on days with a session planned</string>
    <string name="reminder_title">%1$s today</string>
    <string name="reminder_text">%1$d minutes planned. Tap to open the course.</string>
</resources>
```

## Creating it

```kotlin
// app/src/main/java/com/example/planner/notify/Channels.kt
package com.example.planner.notify

import android.content.Context
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationManagerCompat
import com.example.planner.R

const val CHANNEL_REMINDERS = "reminders"

fun createChannels(context: Context) {
    val reminders = NotificationChannelCompat.Builder(
        CHANNEL_REMINDERS,
        NotificationManagerCompat.IMPORTANCE_DEFAULT,
    )
        .setName(context.getString(R.string.channel_reminders))
        .setDescription(context.getString(R.string.channel_reminders_description))
        .build()
    NotificationManagerCompat.from(context).createNotificationChannel(reminders)
}
```

`NotificationChannelCompat` is `androidx.core`'s wrapper, which does nothing on a phone older than
API 26 and creates the real channel on anything newer; with `minSdk` 26 it is always the second,
and the wrapper keeps the code identical either way. The id, `reminders`, is what every
notification names. The name and the description are what the student reads, so they come from
`strings.xml` and are translated like any other text.

**Creating a channel that already exists changes nothing important.** The system keeps the
importance the student chose and ignores the one in your code, and updates only the name and the
description. That makes it safe to call `createChannels` every time the process starts, which is
what an `Application` class is for:

```kotlin
// app/src/main/java/com/example/planner/PlannerApp.kt
package com.example.planner

import android.app.Application
import com.example.planner.notify.createChannels

class PlannerApp : Application() {
    override fun onCreate() {
        super.onCreate()
        createChannels(this)
    }
}
```

And the manifest names it. It also declares the permission section 05 is about:

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

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

## Checking it

Robolectric creates the application class named in the manifest before each test, so a test sees
the channel exactly as a freshly started app would:

```kotlin
// app/src/test/java/com/example/planner/notify/ChannelTest.kt
package com.example.planner.notify

import android.app.Application
import android.app.NotificationManager
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ChannelTest {
    @Test fun theApplicationRegistersTheChannel() {
        val app = ApplicationProvider.getApplicationContext<Application>()
        val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        println("application class: ${app.javaClass.simpleName}")
        for (c in manager.notificationChannels) {
            println("channel ${c.id}: \"${c.name}\", importance ${c.importance}")
            println("  ${c.description}")
        }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ChannelTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    application class: PlannerApp
    channel reminders: "Study reminders", importance 3
      A nudge on days with a session planned
ChannelTest > theApplicationRegistersTheChannel PASSED
BUILD SUCCESSFUL in 14s
```

**Importance 3 is `IMPORTANCE_DEFAULT`**: the notification goes in the shade and makes the phone's
notification sound, and does not pop up over what the student is doing. The scale runs from 0, which
is the channel switched off, to 4, `IMPORTANCE_HIGH`, which is the banner over the screen that a
messaging app uses. A study reminder is not urgent enough for 4, and choosing it would teach
students to switch the channel off, which is the opposite of what a reminder is for.

**An app cannot raise a channel's importance once it exists.** If you ship 2 and later decide on 3,
the students who installed the earlier version keep 2. The way out is a new channel with a new id,
and deleting the old one, which the student sees in settings as a category that disappeared. Choose
the first importance carefully.
