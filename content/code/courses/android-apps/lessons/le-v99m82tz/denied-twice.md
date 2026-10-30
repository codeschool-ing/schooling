---
title: The student says no twice
version: 1
---

**The whole path, refusal, explanation, second refusal, settings, can be walked in a test**, if the
test plays the part of the system. The system's part is two things: showing the dialog and
answering, and changing what `shouldShowRequestPermissionRationale` says. A Compose test can replace
the first with its own `ActivityResultRegistry`, the object that launches activity results, and
Robolectric's package manager lets it set the second.

```kotlin
// app/src/test/java/com/example/planner/ui/AskTwiceTest.kt
package com.example.planner.ui

import android.Manifest
import androidx.activity.ComponentActivity
import androidx.activity.compose.LocalActivityResultRegistryOwner
import androidx.activity.result.ActivityResultRegistry
import androidx.activity.result.ActivityResultRegistryOwner
import androidx.activity.result.contract.ActivityResultContract
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.printToString
import androidx.core.app.ActivityOptionsCompat
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
class AskTwiceTest {
    @get:Rule val rule = createAndroidComposeRule<ComponentActivity>()
    private val permission = Manifest.permission.POST_NOTIFICATIONS
    private var dialogs = 0

    // Stands in for the system: every request is shown and denied, and Android's
    // advice to explain is true after the first refusal and false after the second.
    private val owner = object : ActivityResultRegistryOwner {
        override val activityResultRegistry = object : ActivityResultRegistry() {
            override fun <I, O> onLaunch(
                requestCode: Int,
                contract: ActivityResultContract<I, O>,
                input: I,
                options: ActivityOptionsCompat?,
            ) {
                dialogs++
                shadowOf(rule.activity.packageManager)
                    .setShouldShowRequestPermissionRationale(permission, dialogs == 1)
                dispatchResult(requestCode, false)
            }
        }
    }

    private fun card() = rule.onRoot().printToString().lines()
        .filter { "Text = " in it }
        .joinToString(" / ") { it.substringAfter("Text = '[").substringBefore("]'") }

    @Test fun deniedTwice() {
        rule.setContent {
            CompositionLocalProvider(LocalActivityResultRegistryOwner provides owner) {
                RemindersSetting()
            }
        }
        println("start            dialogs=$dialogs  ${card()}")
        rule.onNodeWithText("Turn on reminders").performClick()
        println("denied once      dialogs=$dialogs  ${card()}")
        rule.onNodeWithText("Allow notifications").performClick()
        println("denied twice     dialogs=$dialogs  ${card()}")
        rule.onNodeWithText("Open settings").performClick()
        val opened = shadowOf(rule.activity.application).nextStartedActivity
        println("settings opened  ${opened.action}")
    }
}
```

The fake registry is the only invented part, and it is small: every request counts as a dialog
shown, the advice to explain is `true` after the first refusal and `false` after the second, which
is Android 11's rule from section 02, and every answer is a refusal. `LocalActivityResultRegistryOwner`
is how a composition finds its registry, so providing the fake there is enough for the real
`rememberLauncherForActivityResult` to use it. Everything else is the code of sections 03 to 05.

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*AskTwiceTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    start            dialogs=0  Get a reminder on days with a session planned. / Turn on reminders
    denied once      dialogs=1  Reminders need permission to show a notification. The planner sends at most one a day, and never anything else. / Allow notifications
    denied twice     dialogs=2  Notifications are off for the planner. You can turn them on in its settings. / Open settings
    settings opened  android.settings.APP_NOTIFICATION_SETTINGS
AskTwiceTest > deniedTwice PASSED
BUILD SUCCESSFUL in 33s
```

Read it as the student would live it:

1. **Start.** No dialog yet, and the card offers reminders.
2. **Denied once.** One dialog, and the card now explains, with the button that asks again.
3. **Denied twice.** Two dialogs, and the card no longer has a button that asks. It points at
   Settings instead.
4. **Settings.** The tap starts the system's notification settings for the app.

**What the test cannot show is a third tap on "Allow notifications" if the card had kept it.** On a
phone, Google's documentation says the launcher would answer `false` immediately, with no dialog,
and the student would see a button that does nothing. That is the failure section 04's `askedBefore`
exists to prevent, and it was **not run** here, because the fake registry shows a dialog for every
request by construction.

## What the settings page can change

From the app's notification settings the student can allow notifications, which on Android 13 and
later also grants `POST_NOTIFICATIONS`. When they come back, the planner has to notice: section 03's
note on recomputing when the screen resumes is about exactly this. The reverse also happens. A student
can revoke a permission in Settings at any time, and Android ends the app's process when they do,
so an app that checked once at start-up and cached the answer is wrong after that, which is why
`canNotify` in lesson 19 checks on every call.
