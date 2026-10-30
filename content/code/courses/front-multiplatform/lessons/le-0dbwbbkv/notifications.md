---
title: Local notifications, a reminder on the morning
version: 1
---

**A local notification is scheduled by the app itself, on the device, with no server.** That is the
difference from a push notification, which a server sends through Apple's or Google's service and
which needs accounts with both. The planner's "Remind me on" a date schedules one for eight in the
morning of that day.

Asked without anybody to answer, the request comes back undecided:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Guitar --click 'Remind me on 2026-10-21' --wait 300 | tail -n 2
  - button "Photo of my notes"
  - status: notifications are prompt
```

**`prompt` is not a refusal.** It means the question has not been answered, and in this run there
was nobody to answer it: a browser with no window has no dialog to show. `remind()` gives up and says
so, which is the right behaviour for a no as well. Run again with permission granted in advance, as a
person would grant it by pressing Allow:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Guitar --grant notifications --click 'Remind me on 2026-10-21' --wait 300 | tail -n 2
  - button "Photo of my notes"
  - status: reminder at 21/10/2026, 08:00:00
```

The notification for 21 October is scheduled. On the web, the plugin keeps it with a timer in the
page, so it only fires while the tab is open, which is the clearest example in this course of a web
implementation that only stands in for the real one.

## On a phone

On Android and iOS the system holds the schedule. **The notification fires with the app closed**, and
on Android after a restart of the phone too, which is why the plugin's own Android manifest asks to be
told when the device boots. Three rules from the plugin's documentation are worth knowing before the
first one is scheduled:

- **Android 13 and later ask the person**, like iOS. Before 13, notifications were allowed by default.
  Call `requestPermissions()` at a moment where the reason is plain, here when the person presses the
  button, and never as the app opens.
- **Exact timing is a permission of its own on Android 12 and later.** Without
  `SCHEDULE_EXACT_ALARM`, the system may move a notification to save battery; with it, the person can
  still turn exact alarms off in the app's settings.
- **An id is the notification's identity.** Scheduling again with the same id replaces it, which is
  why `remind()` uses the session's number: pressing the button twice leaves one reminder.
