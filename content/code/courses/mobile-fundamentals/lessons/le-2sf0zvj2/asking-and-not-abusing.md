---
title: Asking to notify, and not wasting the answer
version: 1
---

**A notification is the one thing an app can do to a person who is not using it**: light the
screen, make a sound, interrupt a conversation. Both systems therefore make it something the user
grants and can take back, and both give the user finer controls than an on and off switch. An app
that spends this on things nobody asked for gets switched off, and then even its useful reminders
stop arriving.

## The permission, on each platform

**On iOS, an app must ask before it shows alerts, sounds or badges**, and Apple's documentation on
asking permission, as read on 30 October 2026, says the system asks the person once and records the
answer; asking again does not show the prompt again. Its advice about timing could have been
written for the planner: in a task-tracking app that sends reminders, ask after the person schedules
a first task, when they can see what the notifications are for, rather than on first launch. That is
lesson 12's rule about asking at the right moment, applied to notifications.

**iOS also offers provisional authorisation**, a trial that needs no prompt. Notifications sent
under it arrive quietly: no sound or banner and nothing on the lock screen, only in Notification
Centre's history, with buttons to keep them or turn them off. The person decides having seen one,
which is a fairer question than asking before they have.

**On Android, from Android 13, posting notifications is a runtime permission, `POST_NOTIFICATIONS`.**
Android's page on it says that an app newly installed on Android 13 or later has its notifications
**off by default** until it asks and the user agrees, and that an app targeting Android 13 chooses
when the dialog appears. If the user refuses, every channel of the app is blocked.

**And on Android every notification belongs to a channel**, from Android 8.0: a category the app
creates, such as "Session reminders" or "Shared courses", each with an importance. Android's guide to
channels says that once a channel is created the app cannot change its behaviour any more; **the user
has complete control**, and can silence one channel while keeping another. Which is the reason to
make a channel per kind of message, so that a student annoyed by one kind does not have to lose
them all.

The fragments below ask for permission and make the reminders channel; they are adapted from the
same Apple and Android pages and the documentation of `expo-notifications`, and **were not compiled
or run for this course**:

```swift
let center = UNUserNotificationCenter.current()
// .provisional: no prompt now; quiet delivery until the person keeps or turns them off
let granted = try await center.requestAuthorization(options: [.alert, .sound, .provisional])
```

```kotlin
val channel = NotificationChannel(
    "reminders", "Session reminders", NotificationManager.IMPORTANCE_DEFAULT,
)
context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
// Android 13 and later: ask, after the student plans a first session
permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
```

```tsx
import * as Notifications from "expo-notifications";

await Notifications.setNotificationChannelAsync("reminders", {
  name: "Session reminders",
  importance: Notifications.AndroidImportance.DEFAULT,
});
const { status } = await Notifications.requestPermissionsAsync();
```

## What the stores say, and what users do

**Apple writes the rule down.** Guideline 4.5.4 of the App Store Review Guidelines, read on 30 October
2026, says push notifications must not be required for the app to function, should not carry
sensitive personal or confidential information, and should not be used for promotions or direct
marketing unless the customer has explicitly opted in through consent language in the app, with a
way in the app to opt out. It ends by saying that abuse may cost the developer the privilege.

**Users enforce the rest themselves.** Every notification the planner sends is weighed against the
interruption it caused, and the user's answer is a switch in settings that the app cannot flip back.
So the planner's list is short:

| the planner sends | because |
|---|---|
| a reminder 15 minutes before a session the student planned | she asked for it by planning the session, and it is useful on time |
| "Ana shared a course with you" | another person did something that involves her |
| nothing about a new course in the catalogue | that is marketing; it needs an explicit opt-in, and a channel of its own |
| nothing to "bring her back" after three quiet days | it is the message most likely to get every channel switched off |

**And the app works with all of them off.** The week screen, the sessions and the totals do not
depend on a single push arriving, which is both what guideline 4.5.4 asks and what the road at the
start of this lesson makes necessary anyway. A notification is something the planner offers.
The courses after the fork set one up end to end: the `android-apps` course in its lesson 19, the
`ios-apps` course in its lesson 17, and `react-native` in its lesson 16, whichever route you take.
