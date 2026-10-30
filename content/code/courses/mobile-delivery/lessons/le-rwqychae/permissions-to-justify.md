---
title: The permission you have to justify
version: 1
---

**An app that wants the camera, the calendar or the location has to ask the person, and the store
wants to know why it asks at all.** These are two different gates. The system asks the person at
run time; the store asks you at review, and a permission that the app's features do not explain is
one of the reasons lesson 6 lists for rejection.

## The planner's one permission

The planner sends a reminder before a study session. On Android 13 and later, showing a
notification is a **runtime permission**; on iOS, it always was. So the planner asks, and it asks
at the moment it matters: when somebody turns reminders on, not at the first launch, when nobody
knows yet what the app is for.

## The words the person reads

**On iOS, every permission comes with a purpose string**, a sentence in `Info.plist` that the
system shows in the dialog. A permission requested with no string crashes the app, and a vague one
is rejected at review. Apple's guideline 5.1.1 asks that purpose strings describe the use clearly
and completely.

| | the declaration | what the person sees |
|---|---|---|
| Android | `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` in the manifest | the system's own text; the app may explain first with its own screen |
| iOS | a purpose string, such as `NSCalendarsFullAccessUsageDescription`, in `Info.plist` | the app's sentence, inside the system's dialog |
| React Native | the same two, written by Expo's config from `app.json` | the same as each platform |

Notifications on iOS are the exception that proves the table: they need no purpose string, because
the system words the request itself. The calendar is a better example of the rule:

```xml
<!-- Info.plist: the sentence the person reads when the planner asks for the calendar -->
<key>NSCalendarsFullAccessUsageDescription</key>
<string>The planner adds your study sessions to your calendar, so they appear beside everything else.</string>
```

```kotlin
// MainActivity.kt: ask for notifications when reminders are switched on, not at launch
val ask = registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
    reminders.setEnabled(granted)
}
fun onRemindersSwitchedOn() {
    if (Build.VERSION.SDK_INT >= 33) ask.launch(Manifest.permission.POST_NOTIFICATIONS)
    else reminders.setEnabled(true)
}
```

```json
{
  "expo": {
    "ios": {
      "infoPlist": {
        "NSCalendarsFullAccessUsageDescription": "The planner adds your study sessions to your calendar, so they appear beside everything else."
      }
    }
  }
}
```

*None of the three listings was run for this course; they are written from each platform's
documentation.* In an app shown in Portuguese, the purpose string goes in the translation file of
`Info.plist`, and that is the sentence the dialog shows.

## The permissions a store questions

Some permissions need more than a sentence. Google Play asks for a **declaration form** before
it accepts an app using certain ones: reading SMS or the call log, background location, all-files
access, exact alarms, and a few others, each with a list of uses it accepts. An app that asks for
one and does not fit an accepted use is rejected, whatever its purpose string says. **The cheapest
fix is not asking**: the planner needs no exact alarm to remind somebody ten minutes before a
session, because an inexact one is close enough.
