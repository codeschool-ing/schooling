---
title: Building one, and posting it
version: 1
---

**A notification is built from a few required parts and a handful of optional ones**, with
`NotificationCompat.Builder`: a channel, a small icon, a title, a line of text, and what a tap does.
The planner's reminder needs exactly that.

The small icon comes first because it is the part people get wrong. It is drawn by the system in
the status bar, in one colour, from the icon's shape alone: **every non-transparent pixel becomes
the same colour**, so a full-colour launcher icon turns into a solid square. It has to be a
silhouette on a transparent ground, which is what this vector is, a page with three lines on it:

```xml
<!-- app/src/main/res/drawable/ic_notification.xml -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M6,2h12a2,2 0,0 1,2 2v16a2,2 0,0 1,-2 2H6a2,2 0,0 1,-2 -2V4a2,2 0,0 1,2 -2zM8,7v2h8V7zM8,11v2h8v-2zM8,15v2h5v-2z" />
</vector>
```

## The function

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/notify/Reminders.kt", "parts": [{"code": "// app/src/main/java/com/example/planner/notify/Reminders.kt\npackage com.example.planner.notify\n\nimport android.Manifest\nimport android.annotation.SuppressLint\nimport android.app.PendingIntent\nimport android.content.Context\nimport android.content.Intent\nimport android.content.pm.PackageManager\nimport android.os.Build\nimport androidx.core.app.NotificationCompat\nimport androidx.core.app.NotificationManagerCompat\nimport androidx.core.content.ContextCompat\nimport com.example.planner.MainActivity\nimport com.example.planner.R\n"}, {"code": "const val EXTRA_COURSE_ID = \"courseId\"\n", "note": "The extra's name is a constant because two other places read it: the activity a tap opens, and section 06's test."}, {"code": "fun canNotify(context: Context): Boolean {\n    if (Build.VERSION.SDK_INT >= 33 &&\n        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=\n        PackageManager.PERMISSION_GRANTED\n    ) return false\n    return NotificationManagerCompat.from(context).areNotificationsEnabled()\n}\n", "note": "**The first two gates of section 02, checked by the app itself.** `Build.VERSION.SDK_INT` is the Android the phone is running; below 33 there is no permission to hold. Then the student's switch for the whole app."}, {"code": "@SuppressLint(\"MissingPermission\") // canNotify checks it on the first line\nfun showReminder(context: Context, courseId: String, courseName: String, minutes: Int): Boolean {\n    if (!canNotify(context)) return false", "note": "`notify` is marked as needing the permission, and the lint check cannot see that `canNotify` checked it in another function, so the warning is silenced here, with the reason beside it."}, {"code": "    val open = Intent(context, MainActivity::class.java)\n        .putExtra(EXTRA_COURSE_ID, courseId)\n        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)\n    val tap = PendingIntent.getActivity(\n        context,\n        courseId.hashCode(),\n        open,\n        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,\n    )", "note": "What a tap does is a `PendingIntent`: an intent the system fires later on the app's behalf. Section 06 is about its flags and its request code."}, {"code": "    val notification = NotificationCompat.Builder(context, CHANNEL_REMINDERS)\n        .setSmallIcon(R.drawable.ic_notification)\n        .setContentTitle(context.getString(R.string.reminder_title, courseName))\n        .setContentText(context.getString(R.string.reminder_text, minutes))\n        .setContentIntent(tap)\n        .setAutoCancel(true)\n        .build()", "note": "The builder: the channel, the silhouette icon, a title and a line, the tap, and `setAutoCancel`, which removes the notification when it is tapped."}, {"code": "    NotificationManagerCompat.from(context).notify(courseId.hashCode(), notification)\n    return true\n}", "note": "The id, here the course id's `hashCode`, is the notification's identity in the shade. Posting again with the same id replaces it, which section 06 tests."}]}
```

## What the shade receives

A test cannot see the shade, but it can ask what was posted. This one grants the permission first,
because without it the first gate stops everything, which is section 05's subject:

```kotlin
// app/src/test/java/com/example/planner/notify/ReminderTest.kt
package com.example.planner.notify

import android.Manifest
import android.app.Application
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.test.core.app.ApplicationProvider
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
class ReminderTest {
    private val app = ApplicationProvider.getApplicationContext<Application>()
    private val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Test fun whatTheShadeReceives() {
        shadowOf(app).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        val shown = showReminder(app, "kotlin", "Kotlin", 45)
        val n = shadowOf(manager).allNotifications.single()
        println("shown = $shown")
        println("  title   ${n.extras.getString(NotificationCompat.EXTRA_TITLE)}")
        println("  text    ${n.extras.getString(NotificationCompat.EXTRA_TEXT)}")
        println("  channel ${n.channelId}")
        println("  icon    ${app.resources.getResourceEntryName(n.smallIcon.resId)}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ReminderTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    shown = true
      title   Kotlin today
      text    45 minutes planned. Tap to open the course.
      channel reminders
      icon    ic_notification
ReminderTest > whatTheShadeReceives PASSED
BUILD SUCCESSFUL in 14s
```

Everything the student will see is there: the course in the title, the minutes in the text, the
channel of section 03 and the icon of this section. The words came from `strings.xml` with the
course and the minutes put into them by `getString`, which is why a Portuguese phone would read a
Portuguese sentence once `values-pt` carries one.

**`notify` returned nothing, and `showReminder` answered `true` only because it checked first.**
Section 05 shows what happens when it does not.
