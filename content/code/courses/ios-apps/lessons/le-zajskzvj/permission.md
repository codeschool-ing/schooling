---
title: Asking, once, at the right moment
version: 1
---

**An app may not show a notification until the person has said yes, and it gets one chance to ask.**
Apple's documentation for asking permission to use notifications is direct about both: the first
request shows the system's prompt and records the answer, and "subsequent authorization requests don't
prompt the person". A no is a no until the person changes it in Settings, which most people never do.
Nothing in this section was run; it follows that documentation and the documentation for
`UNUserNotificationCenter`, read on 30 October 2026.

## When to ask

The commonest mistake is asking at launch, before the person has seen what the app does. The
documentation gives the alternative in its own example: "in a task-tracking app that sends reminder
notifications, you might make the request after the person schedules a first task". **The planner is
that app**, so it asks when the student adds a first session and turns on its reminder, the moment the
question has an obvious reason:

```swift
// Asking when the first reminder is turned on
import UserNotifications

func turnOnReminders() async -> Bool {
    let center = UNUserNotificationCenter.current()
    do {
        return try await center.requestAuthorization(options: [.alert, .sound])
    } catch {
        reminderError = error        // shown under the switch
        return false
    }
}
```

`requestAuthorization(options:)` asks for what the planner uses, an alert and a sound, and nothing
else: the documentation tells an app to "request only the authorization options that you plan to use".
A badge on the icon, counting sessions not done, would be one more thing to explain and one more reason
to say no.

The `Bool` that comes back is `true` when the person allowed one or more of the options and `false`
when they denied or have not decided. When the screen needs to know which, it asks for the current
settings with `notificationSettings()`, the `async` form of `getNotificationSettings(completionHandler:)`,
whose `authorizationStatus` distinguishes them.

## Before asking: the explanation is the app's

The system's prompt shows the app's name and the buttons, and nothing about why. So the planner
explains first, in its own words, on the switch that turns reminders on: "Remind me the evening before
each session". **The person taps that switch, and only then does the system ask**, so its prompt answers
a question the person has just asked themselves.

## Provisional: try first, decide later

The documentation describes a second way, **provisional authorization**, requested with the
`.provisional` option. It shows no prompt at all. Notifications arrive quietly, in Notification Centre
only, with buttons to keep them or turn them off, so the person decides after seeing one rather than
before. For reminders a student explicitly switched on it is the wrong fit, because they asked to be
interrupted; for a weekly summary the student never asked for, it is the honest way to offer it.

## When the answer is no

The planner keeps working: a denied reminder is a missing nicety, never a broken plan. The switch shows
that reminders are off in Settings, with a button that opens the app's page there. Lesson 18 is about
every permission's refusal path, and this one follows the same rule: **say what is off, say where to
turn it on, and never ask again in a loop**, which the system would not show anyway.
