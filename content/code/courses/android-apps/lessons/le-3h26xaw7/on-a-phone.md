---
title: What only a phone shows
version: 1
---

**Everything a student actually sees of a notification is drawn by the system**, and this course
could not show it: the recording machine had no device and no emulator, for the reasons of lesson 1
section 02. This section says what to look for when you run the planner on yours. **Not run**: it
is taken from Google's documentation on notifications and on the Android 13 permission, read on 30
October 2026.

## The permission dialog

On Android 13 and later, once lesson 20 asks, the system shows a dialog with the app's name and two
buttons, *Allow* and *Don't allow*. The app cannot style it, word it or add a button to it. If the
student dismisses it by tapping outside, nothing is decided and the app may ask again; lesson 20 is
about what happens after two refusals.

## The shade and the status bar

A posted reminder appears in the notification shade with the planner's name, the small icon, the
title and the text. The small icon also appears in the status bar at the top of the screen, which is
where a full-colour icon would show as a white square. With `IMPORTANCE_DEFAULT` the phone plays
its notification sound, unless the student has it on silent; it does not appear over the app the
student is using.

## The channel's settings

Long-pressing the notification, or opening the app's notification settings, shows the channel by
the name and description section 03 gave it: *Study reminders*, *A nudge on days with a session
planned*. From there the student can silence it, turn it off, or let it appear over the screen.
**This is the screen to check your channel names on**, because it is the only place most students
ever read them.

## Trying it from a terminal

With a phone or an emulator connected, Google's documentation lists commands to inspect what the
app posted and how its channels are set:

```sh
adb shell dumpsys notification --noredact
adb shell cmd notification list
```

And to grant or revoke the permission without the dialog, which is how instrumented tests and
manual checks reach each of section 05's four phones:

```sh
adb shell pm grant com.example.planner android.permission.POST_NOTIFICATIONS
adb shell pm revoke com.example.planner android.permission.POST_NOTIFICATIONS
```

None of the four commands was run for this course, and so no output is shown.

## Do Not Disturb, and the student who is busy

A phone in Do Not Disturb keeps the notification in the shade and makes no sound, whatever the
channel's importance, unless the student has exempted the app. **That is the correct behaviour for a
study reminder**, and nothing in the planner tries to get around it: a reminder that interrupts an
exam to say it is time to study has misunderstood its job.
