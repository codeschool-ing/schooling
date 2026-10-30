---
title: The permission Android 13 introduced
version: 1
---

**From Android 13, API 33, an app may post notifications only after the student has said yes.**
Until then every app could, and enough of them used notifications for advertising that Google made
it a runtime permission, `POST_NOTIFICATIONS`, like the camera or the location. `mobile-fundamentals`
lesson 12 argues when to ask for a permission; lesson 20 of this course builds the asking. This
section is about what the app does with the answer, and with the phones where there is no question.

## Declared in the manifest, granted at run time

The manifest of section 03 already carries the line:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**Declaring is necessary and not sufficient.** Without the line, the system will never show the
student the dialog, and the app can never hold the permission on Android 13 or later. With it, the
permission exists to be asked for, and the student's answer is what grants it.

There is one exception worth knowing, from Google's documentation and not run here: an app that
targets 32 or lower, installed on Android 13, has the dialog shown by the system itself, around the
time the app creates its first notification channel. This project targets 36, so it is the app's job to ask, at a moment
it chooses.

## Four phones, one function

`canNotify` from section 04 is the whole decision. The first four tests run it on four phones:
Android 15 with and without the permission, Android 15 with the permission and the app's
notifications switched off by the student, and Android 12, where the permission does not exist.
Robolectric's `@Config(sdk = [32])` runs a test as Android 12. The last two tests are about what
happens without `canNotify`, and the end of this section reads them:

```kotlin
// app/src/test/java/com/example/planner/notify/PermissionTest.kt
package com.example.planner.notify

import android.Manifest
import android.annotation.SuppressLint
import android.app.Application
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.test.core.app.ApplicationProvider
import com.example.planner.R
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
class PermissionTest {
    private val app = ApplicationProvider.getApplicationContext<Application>()
    private val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun report(label: String) {
        val shown = showReminder(app, "kotlin", "Kotlin", 45)
        val count = shadowOf(manager).allNotifications.size
        println("API ${Build.VERSION.SDK_INT}, $label: shown = $shown, in the shade = $count")
    }

    @Test fun notGranted() = report("not granted")

    @Test fun granted() {
        shadowOf(app).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        report("granted")
    }

    @Test fun grantedButTurnedOff() {
        shadowOf(app).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        shadowOf(manager).setNotificationsEnabled(false)
        report("granted, then turned off in settings")
    }

    @Config(sdk = [32])
    @Test fun beforeAndroid13() = report("never asked")

    @Config(sdk = [32])
    @Test fun theCheckAloneOnAndroid12() {
        val r = ContextCompat.checkSelfPermission(app, Manifest.permission.POST_NOTIFICATIONS)
        val answer = if (r == PackageManager.PERMISSION_GRANTED) "granted" else "denied"
        println("API ${Build.VERSION.SDK_INT}, checkSelfPermission without the SDK_INT test: $answer")
    }

    @SuppressLint("MissingPermission")
    @Test fun notifyWithNoCheckAtAll() {
        val n = NotificationCompat.Builder(app, CHANNEL_REMINDERS)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("unchecked")
            .build()
        NotificationManagerCompat.from(app).notify(1, n)
        val count = shadowOf(manager).allNotifications.size
        println("API ${Build.VERSION.SDK_INT}, not granted, notify called anyway: in the shade = $count")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.notGranted' 2>&1 | grep '^    '
    API 35, not granted: shown = false, in the shade = 0
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.granted' 2>&1 | grep '^    '
    API 35, granted: shown = true, in the shade = 1
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.grantedButTurnedOff' 2>&1 | grep '^    '
    API 35, granted, then turned off in settings: shown = false, in the shade = 0
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.beforeAndroid13' 2>&1 | grep '^    '
    API 32, never asked: shown = true, in the shade = 1
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.theCheckAloneOnAndroid12' 2>&1 | grep '^    '
    API 32, checkSelfPermission without the SDK_INT test: granted
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.notifyWithNoCheckAtAll' 2>&1 | grep '^    '
    API 35, not granted, notify called anyway: in the shade = 1
```

**The answer is `false` in two different situations, and they need different responses.** Not
granted means the app can still ask, and lesson 20 shows when and how. Granted and then turned off in settings means the student made a decision in a place your app does not control. Asking again is not possible; the honest response is to show the reminder inside the app and, at most, a line saying where the setting is.

On Android 12 the function answered `true` with nothing granted, because `canNotify` skips the
permission check below 33. **The `SDK_INT` test states the rule in the code rather than leaving it
to whatever `checkSelfPermission` answers about a permission that version of Android does not
define.** The fifth result shows what Robolectric's Android 12 answers for the check on its own:
granted. What a real Android 12 phone answers was not checked for this course, and with the
`SDK_INT` test the planner does not depend on it.

## What happens if the app does not check

The last test skips every check and calls `notify` directly, without the permission, on Android 15.
**Robolectric posted it**: one notification in the shade. That is a limit of the stand-in, not the
rule. On a phone, Google's documentation says that a notification from an app without the
permission is dropped, with no exception and nothing in the shade; that was **not run** here. It is
one more reason the check lives in `showReminder`: a test of code that skipped it would pass, and
the student would see nothing.
