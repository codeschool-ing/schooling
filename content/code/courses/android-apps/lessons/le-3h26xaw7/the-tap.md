---
title: The tap, and the notification that replaces itself
version: 1
---

**A tap on a notification is an intent fired by the system, later, on the app's behalf.** That is what a `PendingIntent` is: an `Intent` wrapped with your app's identity, so that the system can start your activity when the student taps, even if your process died hours ago. The planner's tap
opens `MainActivity` with the course id as an extra; lesson 9's navigation would take it from there
to the course's screen.

Three details in section 04's code decide whether that works, and each has a failure you would only
find on a phone:

- **`FLAG_IMMUTABLE`.** Since Android 12 every `PendingIntent` must say whether another app may fill
  in its blanks, and creating one without saying throws an `IllegalArgumentException`. Immutable is
  the right answer whenever nothing needs to change the intent, which is almost always: it means the
  system fires exactly what you built.
- **The request code, `courseId.hashCode()`.** The system treats two `PendingIntent`s as the same if
  their intents match apart from the extras, and keeps one. With a constant request code, the
  reminder for Kotlin and the reminder for SQL would share one `PendingIntent`, and with
  `FLAG_UPDATE_CURRENT` both taps would open whichever course was posted last. A different request
  code per course keeps them apart.
- **`FLAG_ACTIVITY_NEW_TASK` with `FLAG_ACTIVITY_CLEAR_TOP`.** The tap starts the activity from
  outside the app, which needs a task to put it in; clearing the top brings back the existing
  `MainActivity` rather than stacking a second one on the back stack lesson 9 describes.

## One notification per course

The notification id in `notify` plays the same part in the shade. Posting with an id that is already
showing **replaces** that notification instead of adding a second one, which is what a reminder
wants: if the planner recalculates Kotlin's minutes, the student should see the new number, once.

```kotlin
// app/src/test/java/com/example/planner/notify/ReplaceTest.kt
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
class ReplaceTest {
    private val app = ApplicationProvider.getApplicationContext<Application>()
    private val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Test fun oneNotificationPerCourseAndATapThatOpensIt() {
        shadowOf(app).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        showReminder(app, "kotlin", "Kotlin", 45)
        showReminder(app, "kotlin", "Kotlin", 90)
        showReminder(app, "android", "Android Apps", 25)
        val all = shadowOf(manager).allNotifications
        println("three calls, two courses: ${all.size} notifications")
        for (n in all) {
            val tap = shadowOf(n.contentIntent).savedIntent
            println("  ${n.extras.getString(NotificationCompat.EXTRA_TEXT)}")
            println("    tap opens ${tap.component?.shortClassName}, courseId=${tap.getStringExtra(EXTRA_COURSE_ID)}" +
                ", immutable=${n.contentIntent.isImmutable}, auto-cancel=${n.flags and android.app.Notification.FLAG_AUTO_CANCEL != 0}")
        }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ReplaceTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    three calls, two courses: 2 notifications
      25 minutes planned. Tap to open the course.
        tap opens .MainActivity, courseId=android, immutable=true, auto-cancel=true
      90 minutes planned. Tap to open the course.
        tap opens .MainActivity, courseId=kotlin, immutable=true, auto-cancel=true
ReplaceTest > oneNotificationPerCourseAndATapThatOpensIt PASSED
BUILD SUCCESSFUL in 31s
```

Three calls, two notifications. Kotlin's 45 minutes were replaced by its 90, and Android Apps got its
own. Each tap opens `MainActivity` with its own course, the intent is immutable, and auto-cancel is
set, so a tap also clears the notification from the shade.

**A `hashCode` is a convenient id, not a guaranteed one.** Two different strings can share one, and
then two courses would replace each other. With three courses that is a risk nobody will meet; an
app with thousands of items would keep a proper integer id for each, which is what lesson 15's Room
gives every session.

## Grouping, and when not to send at all

Google's documentation describes groups, which fold several notifications from one app into one
expandable entry, and a summary notification for the group. A planner sending one reminder per
course on a busy day is the case they exist for. **The better answer is often fewer
notifications**: one reminder a day that names the day's courses, rather than three. That is a
product decision more than a technical one, and `mobile-fundamentals` lesson 17 makes the case.
